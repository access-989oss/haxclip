"use client";

import React, { useEffect, useRef } from "react";

interface Point3D {
  x: number;
  y: number;
  z: number;
}

export function Hax3DScene() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId: number;
    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const handleResize = () => {
      if (!canvas) return;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    };
    window.addEventListener("resize", handleResize);

    // Mouse parallax tracking
    let targetRotX = 0;
    let targetRotY = 0;
    let rotX = 0;
    let rotY = 0;

    const handleMouseMove = (e: MouseEvent) => {
      const normX = (e.clientX / width) * 2 - 1;
      const normY = (e.clientY / height) * 2 - 1;
      targetRotY = normX * 0.4;
      targetRotX = -normY * 0.4;
    };
    window.addEventListener("mousemove", handleMouseMove);

    // Generate 3D Polyhedron (Icosahedron-like vertices)
    const phi = (1 + Math.sqrt(5)) / 2;
    const baseVertices: Point3D[] = [
      { x: -1, y: phi, z: 0 },
      { x: 1, y: phi, z: 0 },
      { x: -1, y: -phi, z: 0 },
      { x: 1, y: -phi, z: 0 },
      { x: 0, y: -1, z: phi },
      { x: 0, y: 1, z: phi },
      { x: 0, y: -1, z: -phi },
      { x: 0, y: 1, z: -phi },
      { x: phi, y: 0, z: -1 },
      { x: phi, y: 0, z: 1 },
      { x: -phi, y: 0, z: -1 },
      { x: -phi, y: 0, z: 1 },
    ].map((v) => ({
      x: v.x * 120,
      y: v.y * 120,
      z: v.z * 120,
    }));

    // Generate 3D Particle Cloud
    const particleCount = 70;
    const particles: (Point3D & { vx: number; vy: number; vz: number; size: number; hue: number })[] = [];
    for (let i = 0; i < particleCount; i++) {
      particles.push({
        x: (Math.random() - 0.5) * 1600,
        y: (Math.random() - 0.5) * 1000,
        z: Math.random() * 800 - 400,
        vx: (Math.random() - 0.5) * 0.5,
        vy: (Math.random() - 0.5) * 0.5,
        vz: (Math.random() - 0.5) * 0.5,
        size: Math.random() * 2.5 + 1,
        hue: Math.random() > 0.5 ? 260 : 190, // Purple or Cyan
      });
    }

    let angleA = 0;
    let angleB = 0;

    const render = () => {
      ctx.clearRect(0, 0, width, height);

      // Continuous 3D rotation angles
      angleA += 0.006;
      angleB += 0.004;

      // Smooth mouse easing
      rotX += (targetRotX - rotX) * 0.05;
      rotY += (targetRotY - rotY) * 0.05;

      const fov = 450;
      const centerX = width / 2;
      const centerY = height / 2;

      // Draw 3D Background Grid Plane (Horizon Depth)
      ctx.save();
      ctx.strokeStyle = "rgba(99, 102, 241, 0.04)";
      ctx.lineWidth = 1;
      const gridZStep = 80;
      const gridTime = (Date.now() * 0.02) % gridZStep;

      for (let z = 100; z < 800; z += gridZStep) {
        const curZ = z - gridTime;
        const scale = fov / (fov + curZ);
        const yPos = centerY + 180 * scale;
        const halfW = 900 * scale;

        ctx.beginPath();
        ctx.moveTo(centerX - halfW, yPos);
        ctx.lineTo(centerX + halfW, yPos);
        ctx.stroke();
      }
      ctx.restore();

      // Render 3D Floating Particles
      for (let i = 0; i < particles.length; i++) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.z += p.vz;

        if (p.x < -800) p.x = 800;
        if (p.x > 800) p.x = -800;
        if (p.y < -500) p.y = 500;
        if (p.y > 500) p.y = -500;
        if (p.z < -400) p.z = 400;
        if (p.z > 400) p.z = -400;

        const effectiveZ = p.z + 500;
        if (effectiveZ > 0) {
          const scale = fov / (fov + effectiveZ);
          const px = centerX + p.x * scale;
          const py = centerY + p.y * scale;
          const radius = p.size * scale;
          const alpha = Math.min(1, Math.max(0.1, (1 - p.z / 400) * 0.4));

          ctx.beginPath();
          ctx.arc(px, py, Math.max(0.5, radius), 0, Math.PI * 2);
          ctx.fillStyle = `hsla(${p.hue}, 80%, 65%, ${alpha})`;
          ctx.shadowBlur = 8;
          ctx.shadowColor = `hsla(${p.hue}, 90%, 60%, ${alpha})`;
          ctx.fill();
        }
      }
      ctx.shadowBlur = 0;

      // Transform 3D Polyhedron Vertices
      const totalRotY = angleA + rotY;
      const totalRotX = angleB + rotX;

      const cosY = Math.cos(totalRotY);
      const sinY = Math.sin(totalRotY);
      const cosX = Math.cos(totalRotX);
      const sinX = Math.sin(totalRotX);

      const transformed = baseVertices.map((v) => {
        // Rotate around Y
        const x1 = v.x * cosY + v.z * sinY;
        const z1 = -v.x * sinY + v.z * cosY;

        // Rotate around X
        const y2 = v.y * cosX - z1 * sinX;
        const z2 = v.y * sinX + z1 * cosX;

        const cameraZ = z2 + 350;
        const scale = fov / (fov + cameraZ);

        return {
          px: centerX + x1 * scale,
          py: centerY + y2 * scale,
          scale,
          z: z2,
        };
      });

      // Draw Edges between nearby vertices
      ctx.lineWidth = 1.2;
      for (let i = 0; i < transformed.length; i++) {
        for (let j = i + 1; j < transformed.length; j++) {
          const dx = baseVertices[i].x - baseVertices[j].x;
          const dy = baseVertices[i].y - baseVertices[j].y;
          const dz = baseVertices[i].z - baseVertices[j].z;
          const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

          // Connect adjacent vertices of the icosahedron (edge length ~200)
          if (dist < 260) {
            const avgZ = (transformed[i].z + transformed[j].z) / 2;
            const alpha = Math.max(0.04, Math.min(0.28, (avgZ + 150) / 300));

            ctx.beginPath();
            ctx.moveTo(transformed[i].px, transformed[i].py);
            ctx.lineTo(transformed[j].px, transformed[j].py);

            // Shimmering neon gradient line
            const grad = ctx.createLinearGradient(
              transformed[i].px,
              transformed[i].py,
              transformed[j].px,
              transformed[j].py
            );
            grad.addColorStop(0, `rgba(147, 51, 234, ${alpha * 0.9})`); // Violet
            grad.addColorStop(1, `rgba(6, 182, 212, ${alpha * 0.9})`); // Cyan
            ctx.strokeStyle = grad;
            ctx.stroke();
          }
        }
      }

      // Draw Glowing Vertices
      for (const v of transformed) {
        const radius = Math.max(1.5, 3.5 * v.scale);
        const alpha = Math.max(0.15, Math.min(0.85, (v.z + 150) / 300));

        ctx.beginPath();
        ctx.arc(v.px, v.py, radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(167, 139, 250, ${alpha})`;
        ctx.shadowBlur = 12 * v.scale;
        ctx.shadowColor = `rgba(6, 182, 212, ${alpha})`;
        ctx.fill();
      }
      ctx.shadowBlur = 0;

      // Floating 3D Orbiting Halo Ring
      ctx.save();
      ctx.beginPath();
      const ringRadius = 190;
      const ringTilt = Math.PI / 3;
      const cosR = Math.cos(ringTilt);

      for (let t = 0; t <= Math.PI * 2 + 0.1; t += 0.1) {
        const rx = Math.cos(t + angleA * 0.8) * ringRadius;
        const ry = Math.sin(t + angleA * 0.8) * ringRadius * cosR;
        const rz = Math.sin(t + angleA * 0.8) * ringRadius * Math.sin(ringTilt);

        // Apply Y and X rotations
        const rx1 = rx * cosY + rz * sinY;
        const rz1 = -rx * sinY + rz * cosY;
        const ry2 = ry * cosX - rz1 * sinX;
        const rz2 = ry * sinX + rz1 * cosX;

        const scale = fov / (fov + (rz2 + 350));
        const px = centerX + rx1 * scale;
        const py = centerY + ry2 * scale;

        if (t === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.strokeStyle = "rgba(139, 92, 246, 0.18)";
      ctx.lineWidth = 1.5;
      ctx.stroke();
      ctx.restore();

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("mousemove", handleMouseMove);
      cancelAnimationFrame(animationFrameId);
    };
  }, []);

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
    >
      {/* Dynamic 3D ambient radial glow spheres */}
      <div className="absolute -top-40 -left-40 size-[600px] rounded-full bg-gradient-to-tr from-violet-600/15 via-indigo-500/10 to-transparent blur-[120px] animate-pulse" />
      <div className="absolute -bottom-40 -right-40 size-[600px] rounded-full bg-gradient-to-bl from-cyan-500/15 via-sky-600/10 to-transparent blur-[120px] animate-pulse" style={{ animationDuration: "8s" }} />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 size-[800px] rounded-full bg-indigo-950/20 blur-[150px] pointer-events-none" />

      {/* 3D Canvas */}
      <canvas
        ref={canvasRef}
        className="absolute inset-0 size-full opacity-70 transition-opacity duration-1000 dark:opacity-85"
      />
    </div>
  );
}
