document.documentElement.classList.add("js");

const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const revealItems = document.querySelectorAll(".reveal");

if ("IntersectionObserver" in window) {
	const revealObserver = new IntersectionObserver(
		(entries) => {
			entries.forEach((entry) => {
				if (entry.isIntersecting) {
					entry.target.classList.add("is-visible");
					revealObserver.unobserve(entry.target);
				}
			});
		},
		{ threshold: 0.14 }
	);

	revealItems.forEach((item) => revealObserver.observe(item));
} else {
	revealItems.forEach((item) => item.classList.add("is-visible"));
}

const sectionLinks = Array.from(document.querySelectorAll(".nav-links a"));
const linkedSections = sectionLinks
	.map((link) => document.querySelector(link.getAttribute("href")))
	.filter(Boolean);

if ("IntersectionObserver" in window) {
	const navObserver = new IntersectionObserver(
		(entries) => {
			entries.forEach((entry) => {
				if (!entry.isIntersecting) {
					return;
				}

				sectionLinks.forEach((link) => {
					link.classList.toggle("is-active", link.getAttribute("href") === `#${entry.target.id}`);
				});
			});
		},
		{
			rootMargin: "-35% 0px -55% 0px",
			threshold: 0,
		}
	);

	linkedSections.forEach((section) => navObserver.observe(section));
}

const copyText = async (text) => {
	if (navigator.clipboard && window.isSecureContext) {
		await navigator.clipboard.writeText(text);
		return;
	}

	const textarea = document.createElement("textarea");
	textarea.value = text;
	textarea.setAttribute("readonly", "");
	textarea.style.position = "fixed";
	textarea.style.opacity = "0";
	document.body.appendChild(textarea);
	textarea.select();
	document.execCommand("copy");
	textarea.remove();
};

document.querySelectorAll("[data-copy]").forEach((button) => {
	button.addEventListener("click", async () => {
		const originalText = button.textContent.trim();
		const payload = button.getAttribute("data-copy").replaceAll("\\n", "\n");

		try {
			await copyText(payload);
			button.textContent = "Copied";
			button.classList.add("is-copied");
		} catch {
			button.textContent = "Failed";
		}

		window.setTimeout(() => {
			button.textContent = originalText;
			button.classList.remove("is-copied");
		}, 1400);
	});
});

const canvas = document.getElementById("lifecycleCanvas");
const statusText = document.getElementById("visual-status");
const logText = document.getElementById("visual-log-text");

if (canvas) {
	const ctx = canvas.getContext("2d");
	const phases = [
		{
			name: "Tracking resources",
			log: "Connections, tweens and instances enter the scope.",
			cleaned: 0,
			accent: "#70e2a2",
		},
		{
			name: "Replacing tagged tween",
			log: "ReplaceTween cancels the old tagged tween before storing the new one.",
			cleaned: 1,
			accent: "#ffc66d",
		},
		{
			name: "Cleaning temporary hitbox",
			log: "AddTemporary removes a short-lived hitbox without destroying the whole scope.",
			cleaned: 2,
			accent: "#78a8ff",
		},
		{
			name: "Destroying scope",
			log: "Destroy runs final cleanup and closes the lifetime.",
			cleaned: 5,
			accent: "#ff8068",
		},
		{
			name: "Scope reset",
			log: "A new scope can own the next weapon, UI screen or projectile.",
			cleaned: 0,
			accent: "#70e2a2",
		},
	];

	const resources = [
		{ label: "Connection", method: "Disconnect", angle: -2.45, radius: 180 },
		{ label: "Tween", method: "Cancel", angle: -1.1, radius: 160 },
		{ label: "Hitbox", method: "Destroy", angle: 0.18, radius: 184 },
		{ label: "Promise", method: "cancel", angle: 1.35, radius: 166 },
		{ label: "Thread", method: "close", angle: 2.45, radius: 154 },
	];

	let width = 0;
	let height = 0;
	let lastPhase = -1;

	const resizeCanvas = () => {
		const rect = canvas.getBoundingClientRect();
		const ratio = Math.min(window.devicePixelRatio || 1, 2);
		width = Math.max(320, Math.floor(rect.width));
		height = Math.max(320, Math.floor(rect.height));
		canvas.width = Math.floor(width * ratio);
		canvas.height = Math.floor(height * ratio);
		ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
	};

	const drawRoundedRect = (x, y, w, h, radius) => {
		const r = Math.min(radius, w / 2, h / 2);
		ctx.beginPath();
		ctx.moveTo(x + r, y);
		ctx.arcTo(x + w, y, x + w, y + h, r);
		ctx.arcTo(x + w, y + h, x, y + h, r);
		ctx.arcTo(x, y + h, x, y, r);
		ctx.arcTo(x, y, x + w, y, r);
		ctx.closePath();
	};

	const drawLabel = (text, x, y, options = {}) => {
		ctx.font = `${options.weight || 700} ${options.size || 13}px Inter, system-ui, sans-serif`;
		ctx.fillStyle = options.color || "#f4f1e7";
		ctx.textAlign = options.align || "center";
		ctx.textBaseline = "middle";
		ctx.fillText(text, x, y);
	};

	const drawNode = (resource, index, centerX, centerY, phase, time) => {
		const drift = prefersReducedMotion ? 0 : Math.sin(time / 740 + index) * 7;
		const x = centerX + Math.cos(resource.angle) * (resource.radius + drift);
		const y = centerY + Math.sin(resource.angle) * (resource.radius + drift * 0.55);
		const cleaned = index < phase.cleaned;
		const active = index === phase.cleaned - 1;
		const nodeWidth = 126;
		const nodeHeight = 50;

		ctx.save();
		ctx.globalAlpha = cleaned ? 0.42 : 1;
		ctx.strokeStyle = cleaned ? "rgba(255, 128, 104, 0.5)" : "rgba(244, 241, 231, 0.24)";
		ctx.fillStyle = cleaned ? "rgba(255, 128, 104, 0.08)" : "rgba(244, 241, 231, 0.07)";
		drawRoundedRect(x - nodeWidth / 2, y - nodeHeight / 2, nodeWidth, nodeHeight, 8);
		ctx.fill();
		ctx.stroke();

		if (active && !prefersReducedMotion) {
			ctx.strokeStyle = phase.accent;
			ctx.lineWidth = 2;
			drawRoundedRect(x - nodeWidth / 2 - 4, y - nodeHeight / 2 - 4, nodeWidth + 8, nodeHeight + 8, 10);
			ctx.stroke();
		}

		drawLabel(resource.label, x, y - 8, { size: 13, color: cleaned ? "#ffad9e" : "#f4f1e7" });
		drawLabel(resource.method, x, y + 12, { size: 10, weight: 600, color: cleaned ? "#c58176" : "#918d7d" });
		ctx.restore();

		return { x, y, cleaned };
	};

	const draw = (time = 0) => {
		if (!ctx) {
			return;
		}

		ctx.clearRect(0, 0, width, height);

		const phaseIndex = prefersReducedMotion ? 0 : Math.floor(time / 2400) % phases.length;
		const phase = phases[phaseIndex];
		const phaseProgress = prefersReducedMotion ? 0.5 : (time % 2400) / 2400;

		if (phaseIndex !== lastPhase) {
			statusText.textContent = phase.name;
			logText.textContent = phase.log;
			lastPhase = phaseIndex;
		}

		const centerX = width / 2;
		const centerY = height / 2 + 12;
		const scale = Math.min(width / 720, height / 520, 1);

		ctx.save();
		ctx.translate(centerX, centerY);
		ctx.scale(scale, scale);
		ctx.translate(-centerX, -centerY);

		const positions = resources.map((resource, index) => {
			const x = centerX + Math.cos(resource.angle) * resource.radius;
			const y = centerY + Math.sin(resource.angle) * resource.radius;
			return { x, y, resource, index };
		});

		positions.forEach((point) => {
			const cleaned = point.index < phase.cleaned;
			ctx.beginPath();
			ctx.moveTo(centerX, centerY);
			ctx.lineTo(point.x, point.y);
			ctx.strokeStyle = cleaned ? "rgba(255, 128, 104, 0.28)" : "rgba(112, 226, 162, 0.2)";
			ctx.lineWidth = cleaned ? 1.5 : 1;
			ctx.stroke();

			if (!prefersReducedMotion) {
				const pulsePosition = (phaseProgress + point.index * 0.16) % 1;
				const pulseX = centerX + (point.x - centerX) * pulsePosition;
				const pulseY = centerY + (point.y - centerY) * pulsePosition;

				ctx.beginPath();
				ctx.arc(pulseX, pulseY, cleaned ? 3 : 4, 0, Math.PI * 2);
				ctx.fillStyle = cleaned ? "rgba(255, 128, 104, 0.8)" : phase.accent;
				ctx.fill();
			}
		});

		ctx.fillStyle = "rgba(112, 226, 162, 0.06)";
		ctx.strokeStyle = "rgba(112, 226, 162, 0.46)";
		ctx.lineWidth = 1.5;
		drawRoundedRect(centerX - 92, centerY - 56, 184, 112, 8);
		ctx.fill();
		ctx.stroke();

		if (!prefersReducedMotion) {
			const glow = 0.2 + Math.sin(time / 420) * 0.08;
			ctx.strokeStyle = `rgba(112, 226, 162, ${glow})`;
			ctx.lineWidth = 8;
			drawRoundedRect(centerX - 100, centerY - 64, 200, 128, 10);
			ctx.stroke();
		}

		drawLabel("GarbageMan", centerX, centerY - 11, { size: 18, weight: 900 });
		drawLabel("Weapon scope", centerX, centerY + 15, { size: 12, weight: 700, color: "#c5c0ad" });

		resources.forEach((resource, index) => {
			drawNode(resource, index, centerX, centerY, phase, time);
		});

		ctx.restore();

		if (!prefersReducedMotion) {
			window.requestAnimationFrame(draw);
		}
	};

	const resizeObserver = new ResizeObserver(() => {
		resizeCanvas();
		draw(performance.now());
	});

	resizeObserver.observe(canvas);
	resizeCanvas();
	draw();
}
