class MoonCraftWordViewer extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
    this.rotationX = -18;
    this.rotationY = -24;
    this.dragging = false;
    this.lastX = 0;
    this.lastY = 0;
    this.raf = 0;
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
  }

  connectedCallback() {
    const word = this.dataset.word || "MoonBit";
    const layers = Array.from({ length: 18 }, (_, index) => {
      const depth = 17 - index;
      return `<span style="transform: translateZ(${-depth}px); filter: brightness(${72 + index * 2}%);">${word}</span>`;
    }).join("");

    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          min-height: 320px;
          border: 1px solid #ead4e3;
          border-radius: 8px;
          background:
            radial-gradient(circle at 30% 20%, rgba(255, 159, 205, 0.32), transparent 34%),
            linear-gradient(145deg, #fff6fb 0%, #f2f5ff 100%);
          overflow: hidden;
          touch-action: none;
          cursor: grab;
        }
        :host(.dragging) { cursor: grabbing; }
        .viewport {
          width: 100%;
          height: 100%;
          min-height: inherit;
          display: grid;
          place-items: center;
          perspective: 900px;
        }
        .word {
          position: relative;
          width: min(82%, 480px);
          height: 132px;
          transform-style: preserve-3d;
          transform: rotateX(var(--rx)) rotateY(var(--ry));
          transition: transform 80ms linear;
        }
        span {
          position: absolute;
          inset: 0;
          display: grid;
          place-items: center;
          color: #ff5cad;
          font: 900 clamp(40px, 6vw, 88px) / 1 ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          letter-spacing: 0;
          text-shadow:
            0 1px 0 #d83d8d,
            0 2px 0 #bd2f7e,
            0 14px 32px rgba(100, 20, 72, 0.28);
          -webkit-text-stroke: 1px rgba(116, 16, 72, 0.22);
          user-select: none;
        }
        span:last-child {
          color: #ff73bd;
          text-shadow:
            0 1px 0 #ffd5eb,
            0 18px 36px rgba(108, 30, 83, 0.25);
        }
        .hint {
          position: absolute;
          right: 16px;
          bottom: 12px;
          color: #7b6674;
          font: 600 12px / 1.2 ui-sans-serif, system-ui, sans-serif;
        }
        @media (prefers-reduced-motion: reduce) {
          .word { transition: none; }
        }
      </style>
      <div class="viewport" aria-label="Draggable pink 3D MoonBit word">
        <div class="word">${layers}</div>
        <div class="hint">drag to rotate</div>
      </div>
    `;
    this.wordElement = this.shadowRoot.querySelector(".word");
    this.setRotation();
    this.addEventListener("pointerdown", (event) => this.onPointerDown(event));
    this.start();
  }

  disconnectedCallback() {
    cancelAnimationFrame(this.raf);
    window.removeEventListener("pointermove", this.onPointerMove);
    window.removeEventListener("pointerup", this.onPointerUp);
  }

  onPointerDown(event) {
    this.dragging = true;
    this.classList.add("dragging");
    this.lastX = event.clientX;
    this.lastY = event.clientY;
    this.setPointerCapture(event.pointerId);
    window.addEventListener("pointermove", this.onPointerMove);
    window.addEventListener("pointerup", this.onPointerUp);
  }

  onPointerMove(event) {
    if (!this.dragging) {
      return;
    }
    this.rotationY += (event.clientX - this.lastX) * 0.35;
    this.rotationX -= (event.clientY - this.lastY) * 0.25;
    this.rotationX = Math.max(-48, Math.min(32, this.rotationX));
    this.lastX = event.clientX;
    this.lastY = event.clientY;
    this.setRotation();
  }

  onPointerUp() {
    this.dragging = false;
    this.classList.remove("dragging");
    window.removeEventListener("pointermove", this.onPointerMove);
    window.removeEventListener("pointerup", this.onPointerUp);
  }

  start() {
    const step = () => {
      if (!this.dragging) {
        this.rotationY += 0.18;
        this.setRotation();
      }
      this.raf = requestAnimationFrame(step);
    };
    this.raf = requestAnimationFrame(step);
  }

  setRotation() {
    if (!this.wordElement) {
      return;
    }
    this.wordElement.style.setProperty("--rx", `${this.rotationX}deg`);
    this.wordElement.style.setProperty("--ry", `${this.rotationY}deg`);
  }
}

customElements.define("mooncraft-word-viewer", MoonCraftWordViewer);
