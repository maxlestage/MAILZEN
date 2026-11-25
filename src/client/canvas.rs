//! The 2D canvases, drawn in Rust: the radar of the hero (a sweep that lights up the
//! threats it finds) and the network of protected messages behind the last call to
//! action. They pause off screen and draw a single still frame for visitors who prefer
//! reduced motion.

use std::cell::{Cell, RefCell};
use std::f64::consts::{PI, TAU};
use std::rc::Rc;

use wasm_bindgen::JsCast;
use wasm_bindgen::prelude::*;
use web_sys::{
    CanvasRenderingContext2d, HtmlCanvasElement, IntersectionObserver, IntersectionObserverEntry,
};

use super::{all, on_passive, reduced_motion, request_frame, window};

pub fn init() {
    for canvas in all("canvas[data-radar]") {
        start(canvas.unchecked_into(), Radar::new());
    }
    for canvas in all("canvas[data-net]") {
        start(canvas.unchecked_into(), Net::new());
    }
}

/// A small deterministic generator (no randomness needed beyond looks).
struct Rng(u64);

impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self
            .0
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        ((self.0 >> 33) as f64) / f64::from(u32::MAX >> 1)
    }
}

trait Scene {
    fn draw(&mut self, ctx: &CanvasRenderingContext2d, w: f64, h: f64, t: f64);
}

struct Surface {
    canvas: HtmlCanvasElement,
    ctx: CanvasRenderingContext2d,
    size: Cell<(f64, f64)>,
}

impl Surface {
    /// Matches the canvas to its CSS size and the screen density.
    fn fit(&self) {
        let rect = self.canvas.get_bounding_client_rect();
        let dpr = window().device_pixel_ratio().clamp(1.0, 2.0);
        let (w, h) = (rect.width().max(1.0), rect.height().max(1.0));
        self.canvas.set_width((w * dpr) as u32);
        self.canvas.set_height((h * dpr) as u32);
        let _ = self.ctx.set_transform(dpr, 0.0, 0.0, dpr, 0.0, 0.0);
        self.size.set((w, h));
    }
}

fn start(canvas: HtmlCanvasElement, scene: impl Scene + 'static) {
    let Some(ctx) = canvas
        .get_context("2d")
        .ok()
        .flatten()
        .and_then(|c| c.dyn_into::<CanvasRenderingContext2d>().ok())
    else {
        return;
    };
    let surface = Rc::new(Surface {
        canvas: canvas.clone(),
        ctx,
        size: Cell::new((1.0, 1.0)),
    });
    surface.fit();
    let scene = Rc::new(RefCell::new(scene));
    if reduced_motion() {
        let (w, h) = surface.size.get();
        scene.borrow_mut().draw(&surface.ctx, w, h, 4200.0);
        return;
    }
    {
        let surface = surface.clone();
        on_passive(&window(), "resize", move |_: web_sys::Event| surface.fit());
    }
    let visible = Rc::new(Cell::new(true));
    {
        let visible = visible.clone();
        let callback = Closure::<dyn Fn(js_sys::Array)>::new(move |entries: js_sys::Array| {
            for entry in entries.iter() {
                if let Ok(entry) = entry.dyn_into::<IntersectionObserverEntry>() {
                    visible.set(entry.is_intersecting());
                }
            }
        });
        if let Ok(io) = IntersectionObserver::new(callback.as_ref().unchecked_ref()) {
            io.observe(&canvas);
        }
        callback.forget();
    }
    request_frame(move |now| {
        if visible.get() {
            let (w, h) = surface.size.get();
            surface.ctx.clear_rect(0.0, 0.0, w, h);
            scene.borrow_mut().draw(&surface.ctx, w, h, now);
        }
        true
    });
}

fn circle(ctx: &CanvasRenderingContext2d, x: f64, y: f64, r: f64) {
    ctx.begin_path();
    let _ = ctx.arc(x, y, r.max(0.0), 0.0, TAU);
}

// ----- Radar -------------------------------------------------------------------------------

#[derive(Clone, Copy)]
enum Kind {
    Safe,
    Caution,
    Threat,
}

struct Blip {
    angle: f64,
    radius: f64,
    kind: Kind,
    /// When the sweep last passed over it (ms).
    seen: f64,
}

struct Radar {
    blips: Vec<Blip>,
    last_angle: f64,
}

impl Radar {
    fn new() -> Radar {
        let mut rng = Rng(0x006d_6169_6c7a_656e);
        let blips = (0..16)
            .map(|i| Blip {
                angle: rng.next() * TAU,
                radius: 0.28 + rng.next() * 0.66,
                kind: match i % 5 {
                    0 => Kind::Threat,
                    1 | 3 => Kind::Caution,
                    _ => Kind::Safe,
                },
                seen: -10_000.0,
            })
            .collect();
        Radar {
            blips,
            last_angle: 0.0,
        }
    }
}

impl Scene for Radar {
    fn draw(&mut self, ctx: &CanvasRenderingContext2d, w: f64, h: f64, t: f64) {
        let (cx, cy) = (w / 2.0, h / 2.0);
        let r = w.min(h) / 2.0 - 4.0;
        // Rings and crosshair.
        ctx.set_line_width(1.0);
        for i in 1..=4 {
            ctx.set_stroke_style_str(&format!(
                "rgba(34,211,238,{:.3})",
                0.08 + 0.04 * f64::from(i)
            ));
            circle(ctx, cx, cy, r * f64::from(i) / 4.0);
            ctx.stroke();
        }
        ctx.set_stroke_style_str("rgba(34,211,238,0.10)");
        ctx.begin_path();
        ctx.move_to(cx - r, cy);
        ctx.line_to(cx + r, cy);
        ctx.move_to(cx, cy - r);
        ctx.line_to(cx, cy + r);
        ctx.stroke();
        // Ticks on the outer ring.
        for i in 0..72 {
            let a = f64::from(i) * TAU / 72.0;
            let inner = if i % 6 == 0 { r - 9.0 } else { r - 4.0 };
            ctx.begin_path();
            ctx.move_to(cx + a.cos() * inner, cy + a.sin() * inner);
            ctx.line_to(cx + a.cos() * r, cy + a.sin() * r);
            ctx.stroke();
        }
        // The sweep: a wedge that fades behind its edge.
        let angle = (t / 1000.0 * 1.15) % TAU;
        let trail = PI * 0.55;
        let slices = 28;
        for i in 0..slices {
            let f = f64::from(i) / f64::from(slices);
            let a0 = angle - trail * (1.0 - f);
            let a1 = angle - trail * (1.0 - f - 1.0 / f64::from(slices));
            ctx.begin_path();
            ctx.move_to(cx, cy);
            let _ = ctx.arc(cx, cy, r, a0, a1 + 0.004);
            ctx.close_path();
            ctx.set_fill_style_str(&format!("rgba(34,211,238,{:.4})", f.powi(3) * 0.28));
            ctx.fill();
        }
        ctx.set_stroke_style_str("rgba(165,243,252,0.9)");
        ctx.set_line_width(1.6);
        ctx.begin_path();
        ctx.move_to(cx, cy);
        ctx.line_to(cx + angle.cos() * r, cy + angle.sin() * r);
        ctx.stroke();
        // Blips light up when the sweep passes over them.
        let previous = self.last_angle;
        for blip in &mut self.blips {
            let passed = if angle >= previous {
                blip.angle > previous && blip.angle <= angle
            } else {
                blip.angle > previous || blip.angle <= angle
            };
            if passed {
                blip.seen = t;
            }
            let age = (t - blip.seen) / 1000.0;
            let glow = (1.0 - age / 4.2).clamp(0.0, 1.0);
            if glow <= 0.0 {
                continue;
            }
            let (x, y) = (
                cx + blip.angle.cos() * blip.radius * r,
                cy + blip.angle.sin() * blip.radius * r,
            );
            let rgb = match blip.kind {
                Kind::Safe => "52,211,153",
                Kind::Caution => "251,146,60",
                Kind::Threat => "248,113,113",
            };
            ctx.set_fill_style_str(&format!("rgba({rgb},{:.3})", glow));
            circle(ctx, x, y, 3.2);
            ctx.fill();
            ctx.set_fill_style_str(&format!("rgba({rgb},{:.3})", glow * 0.25));
            circle(ctx, x, y, 8.0);
            ctx.fill();
            if let Kind::Threat = blip.kind {
                // A threat rings twice.
                for k in 0..2 {
                    let p = ((age - f64::from(k) * 0.35) / 1.4).clamp(0.0, 1.0);
                    if p > 0.0 && p < 1.0 {
                        ctx.set_stroke_style_str(&format!("rgba({rgb},{:.3})", (1.0 - p) * 0.8));
                        ctx.set_line_width(1.4);
                        circle(ctx, x, y, 4.0 + p * 22.0);
                        ctx.stroke();
                    }
                }
            }
        }
        self.last_angle = angle;
    }
}

// ----- Network -----------------------------------------------------------------------------

struct Node {
    x: f64,
    y: f64,
    vx: f64,
    vy: f64,
    threat: bool,
}

struct Packet {
    from: usize,
    to: usize,
    at: f64,
    speed: f64,
}

struct Net {
    nodes: Vec<Node>,
    packets: Vec<Packet>,
    rng: Rng,
    last: f64,
}

impl Net {
    fn new() -> Net {
        let mut rng = Rng(0x7a65_6e21);
        let nodes = (0..34)
            .map(|i| Node {
                x: rng.next(),
                y: rng.next(),
                vx: (rng.next() - 0.5) * 0.00005,
                vy: (rng.next() - 0.5) * 0.00005,
                threat: i % 7 == 0,
            })
            .collect();
        Net {
            nodes,
            packets: Vec::new(),
            rng,
            last: 0.0,
        }
    }
}

impl Scene for Net {
    fn draw(&mut self, ctx: &CanvasRenderingContext2d, w: f64, h: f64, t: f64) {
        let dt = if self.last == 0.0 {
            16.0
        } else {
            (t - self.last).min(50.0)
        };
        self.last = t;
        for n in &mut self.nodes {
            n.x += n.vx * dt;
            n.y += n.vy * dt;
            if !(0.0..=1.0).contains(&n.x) {
                n.vx = -n.vx;
                n.x = n.x.clamp(0.0, 1.0);
            }
            if !(0.0..=1.0).contains(&n.y) {
                n.vy = -n.vy;
                n.y = n.y.clamp(0.0, 1.0);
            }
        }
        let reach = w.max(h) * 0.2;
        let pos = |n: &Node| (n.x * w, n.y * h);
        ctx.set_line_width(1.0);
        for i in 0..self.nodes.len() {
            for j in i + 1..self.nodes.len() {
                let (a, b) = (pos(&self.nodes[i]), pos(&self.nodes[j]));
                let d = ((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2)).sqrt();
                if d < reach {
                    ctx.set_stroke_style_str(&format!(
                        "rgba(34,211,238,{:.3})",
                        (1.0 - d / reach) * 0.22
                    ));
                    ctx.begin_path();
                    ctx.move_to(a.0, a.1);
                    ctx.line_to(b.0, b.1);
                    ctx.stroke();
                }
            }
        }
        // New packets between close nodes.
        if self.packets.len() < 14 && self.rng.next() < 0.08 {
            let from = (self.rng.next() * self.nodes.len() as f64) as usize % self.nodes.len();
            let origin = pos(&self.nodes[from]);
            let to = (0..self.nodes.len())
                .filter(|&j| j != from)
                .min_by(|&a, &b| {
                    let da = dist(origin, pos(&self.nodes[a]));
                    let db = dist(origin, pos(&self.nodes[b]));
                    da.total_cmp(&db)
                });
            if let Some(to) = to {
                self.packets.push(Packet {
                    from,
                    to,
                    at: 0.0,
                    speed: 0.0006 + self.rng.next() * 0.0008,
                });
            }
        }
        for p in &mut self.packets {
            p.at += p.speed * dt;
        }
        self.packets.retain(|p| p.at < 1.0);
        for p in &self.packets {
            let (a, b) = (pos(&self.nodes[p.from]), pos(&self.nodes[p.to]));
            let (x, y) = (a.0 + (b.0 - a.0) * p.at, a.1 + (b.1 - a.1) * p.at);
            ctx.set_fill_style_str("rgba(165,243,252,0.9)");
            circle(ctx, x, y, 1.8);
            ctx.fill();
        }
        // Threats pulse red, then a shield wave turns them green for a while.
        let wave = (t / 1000.0) % 6.0;
        for n in &self.nodes {
            let (x, y) = pos(n);
            if n.threat {
                let cleared = wave > 3.0;
                let rgb = if cleared { "52,211,153" } else { "248,113,113" };
                let pulse = ((t / 300.0).sin() + 1.0) / 2.0;
                ctx.set_fill_style_str(&format!("rgba({rgb},{:.3})", 0.18 + pulse * 0.12));
                circle(ctx, x, y, 7.0 + pulse * 3.0);
                ctx.fill();
                ctx.set_fill_style_str(&format!("rgba({rgb},0.95)"));
                circle(ctx, x, y, 2.6);
                ctx.fill();
            } else {
                ctx.set_fill_style_str("rgba(103,232,249,0.65)");
                circle(ctx, x, y, 1.8);
                ctx.fill();
            }
        }
        if (2.6..3.6).contains(&wave) {
            let p = (wave - 2.6) / 1.0;
            ctx.set_stroke_style_str(&format!("rgba(52,211,153,{:.3})", (1.0 - p) * 0.5));
            ctx.set_line_width(2.0);
            circle(ctx, w / 2.0, h / 2.0, p * w.max(h));
            ctx.stroke();
        }
    }
}

fn dist(a: (f64, f64), b: (f64, f64)) -> f64 {
    ((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2)).sqrt()
}
