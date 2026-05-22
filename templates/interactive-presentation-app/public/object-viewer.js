import * as THREE from "./vendor/three.module.js";
import { FontLoader } from "./vendor/FontLoader.js";
import { TextGeometry } from "./vendor/TextGeometry.js";

class MoonCraftWordViewer extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
    this.raf = 0;
    this.dragging = false;
    this.lastX = 0;
    this.lastY = 0;
    this.targetYaw = -0.06;
    this.targetPitch = -0.12;
    this.idleTime = 0;
    this.cameraZ = 22;
    this.onResize = this.onResize.bind(this);
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
    this.onWheel = this.onWheel.bind(this);
  }

  connectedCallback() {
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          min-height: 320px;
          border: 1px solid #ead4e3;
          border-radius: 8px;
          background:
            radial-gradient(circle at 28% 22%, rgba(255, 159, 205, 0.34), transparent 36%),
            linear-gradient(145deg, #fff6fb 0%, #f2f5ff 100%);
          overflow: hidden;
          touch-action: none;
          cursor: grab;
        }
        :host(.dragging) { cursor: grabbing; }
        .viewport {
          position: relative;
          width: 100%;
          height: 100%;
          min-height: inherit;
        }
        canvas {
          position: absolute;
          inset: 0;
          z-index: 2;
          display: block;
          width: 100%;
          height: 100%;
          pointer-events: none;
        }
        .hint {
          position: absolute;
          right: 16px;
          bottom: 12px;
          z-index: 3;
          color: #7b6674;
          font: 600 12px / 1.2 ui-sans-serif, system-ui, sans-serif;
          pointer-events: none;
        }
      </style>
      <div class="viewport" aria-label="Draggable pink 3D MoonBit word">
        <div class="hint">drag to rotate · wheel to zoom</div>
      </div>
    `;

    this.viewport = this.shadowRoot.querySelector(".viewport");
    this.setupScene();
    this.loadWord(this.dataset.word || "MoonBit").catch(() => {
      this.classList.add("failed");
    });

    this.addEventListener("pointerdown", event => this.onPointerDown(event));
    this.addEventListener("wheel", this.onWheel, { passive: false });
    this.resizeObserver = new ResizeObserver(this.onResize);
    this.resizeObserver.observe(this);
    this.onResize();
    this.animate();
  }

  disconnectedCallback() {
    cancelAnimationFrame(this.raf);
    window.removeEventListener("pointermove", this.onPointerMove);
    window.removeEventListener("pointerup", this.onPointerUp);
    this.resizeObserver?.disconnect();
    this.renderer?.dispose();
    this.disposeScene();
  }

  setupScene() {
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(38, 1, 0.1, 100);
    this.camera.position.set(0, 0, this.cameraZ);

    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    this.renderer.setClearColor(0x000000, 0);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    this.viewport.appendChild(this.renderer.domElement);

    this.scene.add(new THREE.AmbientLight(0xffffff, 1.2));
    const key = new THREE.DirectionalLight(0xffffff, 2.4);
    key.position.set(8, 10, 12);
    this.scene.add(key);
    const rim = new THREE.DirectionalLight(0xff9bd0, 1.3);
    rim.position.set(-8, -3, 8);
    this.scene.add(rim);

    this.word = new THREE.Group();
    this.word.rotation.x = this.targetPitch;
    this.word.rotation.y = this.targetYaw;
    this.scene.add(this.word);
  }

  async loadWord(word) {
    const loader = new FontLoader();
    const fontUrl = new URL("./vendor/helvetiker_bold.typeface.json", import.meta.url);
    const font = await loader.loadAsync(fontUrl.href);
    const geometry = new TextGeometry(word, {
      font,
      size: 1.9,
      depth: 0.48,
      curveSegments: 12,
      bevelEnabled: true,
      bevelThickness: 0.05,
      bevelSize: 0.035,
      bevelSegments: 4,
    });
    geometry.computeBoundingBox();
    geometry.center();

    const material = [
      new THREE.MeshStandardMaterial({
        color: 0xff5fb2,
        roughness: 0.34,
        metalness: 0.12,
        emissive: 0x4a0828,
        emissiveIntensity: 0.08,
      }),
      new THREE.MeshStandardMaterial({
        color: 0xd82f89,
        roughness: 0.5,
        metalness: 0.06,
      }),
    ];
    const mesh = new THREE.Mesh(geometry, material);
    this.word.add(mesh);
    this.classList.add("ready");
  }

  disposeScene() {
    this.scene?.traverse(object => {
      object.geometry?.dispose?.();
      if (Array.isArray(object.material)) {
        object.material.forEach(material => material.dispose?.());
      } else {
        object.material?.dispose?.();
      }
    });
  }

  onResize() {
    if (!this.renderer || !this.camera) {
      return;
    }
    const rect = this.getBoundingClientRect();
    const width = Math.max(1, Math.floor(rect.width));
    const height = Math.max(1, Math.floor(rect.height));
    this.renderer.setSize(width, height, false);
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
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
    this.targetYaw += (event.clientX - this.lastX) * 0.012;
    this.targetPitch += (event.clientY - this.lastY) * 0.008;
    this.targetPitch = Math.max(-0.82, Math.min(0.48, this.targetPitch));
    this.lastX = event.clientX;
    this.lastY = event.clientY;
  }

  onPointerUp() {
    this.dragging = false;
    this.classList.remove("dragging");
    window.removeEventListener("pointermove", this.onPointerMove);
    window.removeEventListener("pointerup", this.onPointerUp);
  }

  onWheel(event) {
    event.preventDefault();
    this.cameraZ = Math.max(14, Math.min(32, this.cameraZ + event.deltaY * 0.01));
  }

  animate() {
    if (!this.dragging) {
      this.idleTime += 0.012;
      this.targetYaw = Math.sin(this.idleTime) * 0.16;
      this.targetPitch = -0.12 + Math.sin(this.idleTime * 0.7) * 0.035;
    }
    this.word.rotation.x += (this.targetPitch - this.word.rotation.x) * 0.12;
    this.word.rotation.y += (this.targetYaw - this.word.rotation.y) * 0.12;
    this.camera.position.z += (this.cameraZ - this.camera.position.z) * 0.12;
    this.renderer.render(this.scene, this.camera);
    this.raf = requestAnimationFrame(() => this.animate());
  }
}

customElements.define("mooncraft-word-viewer", MoonCraftWordViewer);
