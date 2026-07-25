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

Run these in **three positions**, in this order: **where the problem is** (e.g. at the desk), then
**next to the router**, then — the control almost everyone skips — **wired into the router over
Ethernet**.

The wired run is not optional. Standing next to the router is *still Wi-Fi*, so those two positions
can only tell you how much distance costs you; neither can separate "the router or the line is slow"
from "Wi-Fi is slow". Only the cable can. **If wired is at/near plan speed, every remaining fix lives
inside the Wi-Fi path** — no plan upgrade and no new modem will move it. **If wired is also slow,
stop diagnosing Wi-Fi entirely**: it is the router, the WAN link, or the ISP, and steps 3–4 below are
the wrong ladder to climb.

⚠️ **Check the adapter before trusting a slow wired result.** Laptops without a built-in port need a
USB-C/Thunderbolt Ethernet adapter, and a **USB 2.0** one tops out around 300 Mbps — on a gigabit plan
that alone produces a "wired is also slow" reading and sends you chasing the ISP. Confirm the adapter
and the port both negotiate 1 Gbps before believing the third row of the table below.

The tools differ per OS but the four measurements are the same everywhere (macOS / Windows / Linux).
On the **wired** run, skip the *Wi-Fi* bullet — but do not skip the link rate: **read the Ethernet
negotiated speed.** *macOS:* `ifconfig <iface> | grep media` — the speed appears **in parentheses
only while a link is actually up** (`media: autoselect (1000baseT <full-duplex>)`); a bare
`media: autoselect` means nothing is plugged in, not that the command failed. *Windows:* the adapter
Status dialog → Speed, or `Get-NetAdapter | Format-Table Name,LinkSpeed`. *Linux:* `ethtool <iface>`
→ `Speed:`. A link that came up at 100 Mbps instead of 1000 explains the entire result and is the
first thing to rule out:

- **Throughput + bufferbloat.** What matters is whether latency **spikes under load** (bufferbloat),
  not just raw Mbps — a big idle-vs-loaded latency jump wrecks calls and browsing even when Mbps looks
  fine. *macOS:* `networkQuality -v` (reports Mbps + a "Responsiveness" score). *Windows / Linux* (no
  built-in equivalent): a browser test that reports **loaded** latency — `speed.cloudflare.com` or
  `waveform.com/bufferbloat` — or the cross-platform Ookla `speedtest` CLI for throughput.
- **Packet loss & latency.** *macOS / Linux:* `ping -c 100 <gateway>` and `ping -c 100 1.1.1.1`.
  *Windows:* `ping -n 100 <gateway>` and `ping -n 100 1.1.1.1`. (Gateway is usually
  `192.168.0.1`/`192.168.1.1` — find it with `ipconfig` on Windows, `ip route` / `netstat -nr`
  elsewhere.) **Any loss to your own gateway = a Wi-Fi/local problem**, not the ISP.
- **Wi-Fi link quality (signal + negotiated rate).** *Windows:* `netsh wlan show interfaces` → Signal
  (%), Receive/Transmit rate, Radio type, Channel. *macOS:* `system_profiler SPAirPortDataType` — its
  "Current Network Information" block gives PHY Mode, Channel, **Signal / Noise** in dBm and
  **Transmit Rate**, and needs **no sudo**, so prefer it. `wdutil info` reports the same but
  **requires `sudo`**: run bare it prints only a usage message, which reads like the tool is broken
  or missing. (Menu-bar gestures for this have changed across macOS releases; the commands haven't.)
  *Linux:* `iw dev <iface> link` or `nmcli dev wifi` → signal (dBm) + bitrate.
  Read the **signal** (RSSI better than −60 dBm good, worse than −67 weak; on Windows's % scale, >70%
  is good) and whether the **negotiated rate** sits far below the AP's max — a Wi-Fi 6 client stuck at
  an 802.11ac / low rate means distance or interference, not a dead plan.
- **Client sanity.** Interface error counters — *macOS / Linux:* `netstat -i` or `ip -s link`;
  *Windows:* `netstat -e` or PowerShell `Get-NetAdapterStatistics`. Confirm no per-device throttle in
  the router app. Rule the device out before blaming it.

Record numbers for each spot. **The gaps between the three positions are the diagnosis**, and each
gap points at a different layer:

| Desk | Beside router | Wired | Bottleneck |
| --- | --- | --- | --- |
| slow | fast | fast | the **Wi-Fi path** — distance, walls, or a wireless-backhauled extender |
| slow | slow | fast | the **wireless segment** — but not yet *which end*: could be the AP (generation, channel, width, band steering) **or** the client's own radio/driver/band choice. Step 1's signal + negotiated rate, compared against another device on the same AP, tells you which |
| slow | slow | slow | **not the Wi-Fi** — but confirm the test path before escalating (see below) |

The first row is the common one: low throughput with weak signal and some packet loss at the desk,
near-plan speed with strong signal and 0% loss beside the router.

⚠️ **The third row is the one that misleads.** Before blaming the router, WAN link or ISP, rule out
the wired test path itself — the USB adapter or dock, the client's Ethernet port, and the patch
cable are all in it. Re-run from a **different machine with known-good wired hardware**, or into a
different router port with a different cable. Only when the slow result survives that is it genuinely
upstream. Escalating to the ISP on an untested adapter is the expensive version of this mistake.

## 2. Localize the bottleneck

- **ISP plan** — look up the actual subscribed tier (the provider's account portal). If already on the
  top residential tier, a plan upgrade won't help; say so and move inward. Don't recommend paying more
  before the internal path is fixed.
- **Router** — identify the model and its **Wi-Fi generation / max PHY rate**. A Wi-Fi 5 (AC1200,
  ~867 Mbps 5 GHz) router caps you well below a gigabit plan even in ideal conditions. Then check the
  **wired side**, which the Wi-Fi story hides: the **WAN/LAN port's negotiated speed** (the router's
  status page states it) and the **cable** on that run. **~94 Mbps of usable throughput is the
  signature of a link that negotiated 100BASE-TX instead of gigabit** — caused by a Fast-Ethernet
  port, or by a cable delivering only two usable pairs (damaged, miswired, or terminated for 100M).
  Note that Cat5 itself is *not* automatically the culprit: it carries 1000BASE-T fine when all four
  pairs are intact — so read the **negotiated speed**, don't infer it from the cable's printed
  category. From the client this looks exactly like a slow ISP, which is how people end up buying a
  faster plan that changes nothing.
- **Wi-Fi path** — the killer is a **wirelessly-backhauled extender/mesh node**: a dual-band extender
  serving the router on one link and the client on the other **roughly halves** throughput and adds
  latency. Find out if one is in the path (router/mesh UI shows satellite nodes and their clients).
- **Client** — negotiated rate and signal from step 1 tell you if the device is the limit.

## 3. Inspect the router admin UI

Log into the router (browser, default `http://192.168.0.1` / `http://192.168.1.1`, or the vendor host
printed on the router's label). **Read-only first**; only change settings with the owner's OK, one at
a time, re-measuring after each.

**Do not type the owner's admin password yourself** — have them sign in and hand over the session, or
read the settings back to you. The same holds for the ISP account portal in step 2. Router admin
access can re-route or capture every device in the house, so it is theirs to grant, not yours to
take; an agent that stops here loses nothing, because everything below is read-only anyway. Check:

- **QoS / bandwidth control** — off, or not throttling the device? (A stray cap here explains a lot.)
- **Band steering / Smart Connect** — on by default; toggling rarely helps much, but worth an A/B.
- **Channel & width** — Auto is usually fine; a fixed clear channel occasionally helps in RF-dense
  areas, but test it — often it makes no measurable difference, so don't assume.
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
give expected before/after numbers, and confirm the person's appetite — many will happily stop at
"good enough" rather than chase the theoretical maximum, and that's a valid place to stop.

## A worked shape (generic)

A common real-world case: a gigabit plan, a Wi-Fi 5 (AC1200) main router, and a **wirelessly-
backhauled** Wi-Fi 6 extender near the desk. Measurement shows low throughput + weak signal + packet
loss at the desk but near-plan speed beside the router → the extender's wireless hop is halving
bandwidth. The #1 fix is almost always to **wire the extender's backhaul** (put it in Access Point
mode on an Ethernet run) or wire the client directly — not to add a second wireless extender, which
ranks last. Many extenders already have a gigabit port + AP mode, so the fix often costs only a cable.

## Anti-patterns

- Recommending a plan upgrade or a new router **before** measuring the internal path.
- Blaming the ISP without ever running the **wired** test — two Wi-Fi measurements, however careful,
  cannot tell a slow line from a slow radio.
- Trusting a single speed-test number — always compare **idle vs loaded** latency and **desk vs
  router** location, and check **packet loss to the gateway**.
- Adding a **wireless** extender/mesh node to "extend range" — it usually makes throughput worse.
- Changing several router settings at once — change one, re-measure, keep or revert.
