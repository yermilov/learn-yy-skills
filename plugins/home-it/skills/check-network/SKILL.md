---
name: check-network
description: >-
  Diagnose a slow home network end-to-end and recommend the highest-leverage fix. Use when the
  internet or Wi-Fi feels slow — "make my home network/Wi-Fi faster", "speeds are way below my
  plan", "slow at my desk", "should I buy an extender / new router / mesh?", "bufferbloat", "lag on
  calls", «зроби домашню мережу швидшою», «інтернет повільний», «повільний Wi-Fi». Runs a repeatable
  playbook: measure from the machine (throughput, idle-vs-loaded latency/bufferbloat, packet loss,
  Wi-Fi signal & negotiated rate), localize the bottleneck across four layers (ISP plan → router →
  Wi-Fi path → client), inspect the router admin UI, then rank fixes — wired backhaul first, a second
  wireless extender never. Not for public/office networks you don't administer, and not for
  server-side app latency (that's profiling, not this).
---

# check-network — make a home network faster

A slow home network is almost never one thing. Work it as **four layers** and measure before
recommending — the fix that feels obvious (buy an extender) is usually the *worst* option. The goal
of a session is a **ranked recommendation backed by numbers**, not a shopping spree.

The four layers, outermost to innermost:

1. **ISP plan** — what you pay for (e.g. 1 Gbit). Rarely the bottleneck; check it, don't assume it.
2. **Router** — model, Wi-Fi generation, and config (QoS, band steering, channel, mesh).
3. **Wi-Fi path** — distance, walls, interference, and any **wirelessly-backhauled** extender.
4. **Client** — the device's Wi-Fi radio, negotiated rate, drivers, adapter.

## 1. Measure the baseline (from the affected device)

Run these **where the problem is** (e.g. at the desk), then repeat **next to the router** — the gap
between the two is the single most diagnostic number you'll get.

- **Throughput + bufferbloat (macOS):** `networkQuality -v`. Read *both* the Mbps **and** the
  "Responsiveness" — a Low/So-so responsiveness or a big idle-vs-loaded latency jump is **bufferbloat**,
  which wrecks calls and browsing even when Mbps looks fine. (Linux/Windows: a browser speed test that
  reports loaded latency, e.g. Cloudflare/Waveform bufferbloat test.)
- **Packet loss & latency:** `ping -c 100 <gateway>` (default `192.168.0.1`/`192.168.1.1`) and
  `ping -c 100 1.1.1.1`. **Any loss to your own gateway = a Wi-Fi/local problem**, not the ISP.
- **Wi-Fi link quality (macOS):** signal (RSSI; better than −60 dBm is good, worse than −67 is weak)
  and the **negotiated Tx rate** — a Wi-Fi 6 client stuck at an 802.11ac rate or a low Tx rate means
  distance/interference, not a dead plan.
- **Client sanity:** interface error counters (`netstat -i` / `ifconfig`), and confirm no per-device
  throttle in the router app. Rule the device out before blaming it.

Record numbers for each spot. Example of a real "slow desk vs near router" split from this playbook's
reference case: desk Wi-Fi **75–190 Mbps, ~5% loss to router, RSSI −65 to −68 dBm**; moved next to the
router **~600–620 Mbps, 0% loss, RSSI −20 dBm**. That gap *is* the diagnosis — the internal Wi-Fi
path, not the ISP.

## 2. Localize the bottleneck

- **ISP plan** — look up the actual subscribed tier (the provider's account portal). If already on the
  top residential tier, a plan upgrade won't help; say so and move inward. Don't recommend paying more
  before the internal path is fixed.
- **Router** — identify the model and its **Wi-Fi generation / max PHY rate**. A Wi-Fi 5 (AC1200,
  ~867 Mbps 5 GHz) router caps you well below a gigabit plan even in ideal conditions.
- **Wi-Fi path** — the killer is a **wirelessly-backhauled extender/mesh node**: a dual-band extender
  serving the router on one link and the client on the other **roughly halves** throughput and adds
  latency. Find out if one is in the path (router/mesh UI shows satellite nodes and their clients).
- **Client** — negotiated rate and signal from step 1 tell you if the device is the limit.

## 3. Inspect the router admin UI

Log into the router (browser, default `http://192.168.0.1` or the vendor host, e.g.
`http://tplinkwifi.net`). **Read-only first**; only change settings with the user's OK, one at a time,
re-measuring after each. Check:

- **QoS / bandwidth control** — off, or not throttling the device? (A stray cap here explains a lot.)
- **Band steering / Smart Connect** — on by default; toggling rarely helps much, but worth an A/B.
- **Channel & width** — Auto is usually fine; a fixed clear channel occasionally helps in RF-dense
  areas, but test it (in the reference case fixed channels gave *no* improvement — don't assume).
- **Mesh / EasyMesh** — note every satellite node, its IP, and how many clients hang off it, and
  **whether its backhaul is wireless or wired**. Wireless backhaul is the top suspect.
- **MTU / NAT boost / hardware accel** — confirm MTU 1500 (unless PPPoE) and HW acceleration on.

## 4. Diagnose and recommend — the fix ladder

Rank fixes by leverage, not by novelty:

1. **Wired backhaul (almost always #1).** Run an Ethernet cable (Cat5e/Cat6) from the router to the
   room, and put the extender in **Access Point mode** on that cable — or wire the client directly.
   This removes the halving wireless hop for the price of a cable, usually with hardware already owned.
   Expected: near line-rate, single-digit-ms latency, 0% loss.
2. **Relocate / reposition.** Move the AP or the client to cut distance/walls; raise/reorient the AP.
   Free, and step 1's measurements already told you how much it's worth.
3. **Band / channel tuning.** Prefer 5 GHz near the AP; try a clear channel in dense RF. Small wins.
4. **Newer single router** (Wi-Fi 6/6E). A real but bounded upgrade (~+200–350 Mbps) — worth it only
   if wired backhaul isn't possible.
5. **Second *wireless* extender — the last resort, usually a mistake.** It adds another halving hop and
   more latency. When a user asks "should I add another extender?", steer them to wired backhaul first;
   only a **wired** or tri-band-dedicated-backhaul node is worth adding.

Then: name the specific cable/adapter/switch if hardware is needed (with a couple of price points),
give expected before/after numbers, and confirm the user's appetite (many will happily stop at "good
enough" — e.g. 500 Mbps on a gigabit plan — rather than chase the theoretical max; respect that).

## Reference setup (this playbook's proven case)

- **ISP:** Lucky Net, ~1 Gbit residential (top public tier) — **not** the bottleneck.
- **Router:** TP-Link **Archer C64** — Wi-Fi 5 / AC1200, ~867 Mbps 5 GHz, gigabit ports, EasyMesh.
- **Extender:** TP-Link **RE505X** — Wi-Fi 6 / AX1500, **has a gigabit Ethernet port + Access Point
  mode** (so it becomes a wired AP with no new hardware). Was running as a *wireless* mesh node — the
  bottleneck.
- **Client:** MacBook (USB-C only, no RJ45 → needs a USB-C→Gigabit adapter to go wired).
- **Verdict (unanimous across a two-model review):** wired backhaul with the RE505X in AP mode is the
  #1 fix (~600–800 Mbps expected at the desk); adding a second wireless extender ranked dead last.
  User was satisfied stopping at ~500 Mbps over Ethernet.

## Anti-patterns

- Recommending a plan upgrade or a new router **before** measuring the internal path.
- Trusting a single speed-test number — always compare **idle vs loaded** latency and **desk vs
  router** location, and check **packet loss to the gateway**.
- Adding a **wireless** extender/mesh node to "extend range" — it usually makes throughput worse.
- Changing several router settings at once — change one, re-measure, keep or revert.
