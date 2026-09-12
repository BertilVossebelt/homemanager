import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { createState, createBinding, With } from "ags"
import { exec, execAsync } from "ags/process"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth"
import style from "./style.scss"

const { LEFT, TOP, BOTTOM, RIGHT } = Astal.WindowAnchor

// Software screen-dim, used when there's no hardware backlight. `softBright` is
// perceived brightness in [MIN_SOFT_BRIGHT, 1]; the overlay's black opacity is
// its complement — capped so the screen never goes fully black.
const MIN_SOFT_BRIGHT = 0.3
const [softBright, setSoftBright] = createState(1)

// Keep the Waybar clock in sync with this control center: while the sidebar is
// open the bar clock shows the date, otherwise the time. The sidebar's own
// visibility is the single source of truth, so clicking the clock and the
// Super+C keybind (both just `ags toggle sidebar`) can never drift apart.
const CLOCK_MODE_FILE = `${GLib.get_user_cache_dir()}/waybar-clock-mode`
function setClockMode(open: boolean) {
  execAsync([
    "sh",
    "-c",
    `echo ${open ? "date" : "time"} > '${CLOCK_MODE_FILE}'; pkill -RTMIN+8 -f waybar`,
  ]).catch(() => {})
}

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
]
const WEEKDAYS = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

type Cell = { day: number; year: number; month: number; outside: boolean }

// Stable per-day key used to compare against and set the selected date.
const dayKey = (y: number, m: number, d: number) => `${y}-${m}-${d}`

// Build a Sunday-first 6-row grid for `offset` months from the current month.
// Leading/trailing cells are filled with the adjacent months' days (`outside`)
// so the crossover between months is visible.
function monthMatrix(offset: number): { title: string; weeks: Cell[][] } {
  const now = new Date()
  const first = new Date(now.getFullYear(), now.getMonth() + offset, 1)
  const month = first.getMonth()
  const startDow = first.getDay() // getDay() is already Sunday = 0

  const start = new Date(first)
  start.setDate(1 - startDow) // Sunday of the first visible week

  const cells: Cell[] = []
  for (let i = 0; i < 42; i++) {
    const dt = new Date(start)
    dt.setDate(start.getDate() + i)
    cells.push({
      day: dt.getDate(),
      year: dt.getFullYear(),
      month: dt.getMonth(),
      outside: dt.getMonth() !== month,
    })
  }

  const weeks: Cell[][] = []
  for (let i = 0; i < 42; i += 7) weeks.push(cells.slice(i, i + 7))
  return { title: `${MONTHS[month]} ${first.getFullYear()}`, weeks }
}

function Calendar() {
  const [offset, setOffset] = createState(0)
  // The highlighted day. Starts on today; the title button resets it back.
  const today = () => {
    const n = new Date()
    return dayKey(n.getFullYear(), n.getMonth(), n.getDate())
  }
  const [selected, setSelected] = createState(today())
  const jumpToToday = () => {
    setSelected(today())
    setOffset(0)
  }
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="calendar">
      <With value={offset}>
        {(off: number) => {
          const { title, weeks } = monthMatrix(off)
          const onScroll = (_: unknown, e: Astal.ScrollEvent) => {
            const { UP, DOWN } = Gdk.ScrollDirection
            if (e.direction === UP || e.delta_y < 0) setOffset(off - 1)
            else if (e.direction === DOWN || e.delta_y > 0) setOffset(off + 1)
          }
          return (
            <eventbox onScroll={onScroll}>
              <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                <box class="cal-header">
                  <button class="cal-nav" onClicked={() => setOffset(off - 1)}>
                    <label label="‹" />
                  </button>
                  <button
                    class="cal-title-btn"
                    hexpand
                    tooltipText="Jump to today"
                    onClicked={jumpToToday}
                  >
                    <label class="cal-title" label={title} />
                  </button>
                  <button class="cal-nav" onClicked={() => setOffset(off + 1)}>
                    <label label="›" />
                  </button>
                </box>
                <box class="cal-weekdays" homogeneous>
                  {WEEKDAYS.map((w) => (
                    <label class="cal-wd" label={w} />
                  ))}
                </box>
                {weeks.map((week) => (
                  <box class="cal-row" homogeneous>
                    {week.map((cell) => {
                      const key = dayKey(cell.year, cell.month, cell.day)
                      return (
                        <button
                          class={selected.as((sel) =>
                            [
                              "cal-day",
                              cell.outside ? "outside" : "",
                              sel === key ? "selected" : "",
                            ]
                              .filter(Boolean)
                              .join(" "),
                          )}
                          onClicked={() => setSelected(key)}
                          onButtonPressEvent={(_self: Gtk.Button, event: Gdk.EventButton) => {
                            // Single left click selects (via onClicked). Double click
                            // also opens that day in a calendar: left → Proton,
                            // right → Google. Month is 1-based in the URLs, so +1 the
                            // 0-based JS month. Read the button via get_button() — the
                            // union's `button` field reads back undefined in GJS.
                            if (event.type === Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                              // Read the button via get_button(); the union's `button`
                              // field reads back undefined in GJS. get_button() returns
                              // [ok, button] here, but normalize for a bare-number build.
                              // eslint-disable-next-line @typescript-eslint/no-explicit-any
                              const gb: any = (event as any).get_button?.()
                              const button =
                                typeof gb === "number"
                                  ? gb
                                  : Array.isArray(gb)
                                    ? gb[1]
                                    : (event as any).button
                              const date = `${cell.year}/${cell.month + 1}/${cell.day}`
                              const url =
                                button === 3
                                  ? `https://calendar.google.com/calendar/u/1/r/week/${date}`
                                  : `https://calendar.proton.me/u/1/week/${date}`
                              execAsync(["xdg-open", url]).catch(() => {})
                              // Dismiss the control center once we've opened a calendar.
                              app.get_window("sidebar")?.hide()
                            }
                            return false
                          }}
                        >
                          <label label={String(cell.day)} />
                        </button>
                      )
                    })}
                  </box>
                ))}
              </box>
            </eventbox>
          )
        }}
      </With>
    </box>
  )
}

// Audio output volume slider (Wireplumber default speaker).
function VolumeControl() {
  const wp = AstalWp.get_default?.()
  const speaker = wp?.defaultSpeaker
  if (!speaker) return <box />
  const volume = createBinding(speaker, "volume")
  const pct = volume.as((v) => `${Math.round(v * 100)}%`)
  return (
    <box class="qs-row" spacing={12}>
      <label class="qs-icon" label="󰕾" />
      <slider
        hexpand
        class="qs-slider"
        min={0}
        max={1}
        step={0.05}
        value={volume}
        onDragged={(self: Astal.Slider) => speaker.set_volume(self.value)}
        onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, v: number) => {
          speaker.set_volume(Math.max(0, Math.min(1, v)))
          return false
        }}
      />
      <label class="qs-pct" label={pct} />
    </box>
  )
}

// A labelled slider row (icon · slider · percentage) that reacts to both drag
// and scroll. `value`/`pct` are Accessors; `onSet` receives the new 0..1 value.
function SliderRow(props: {
  icon: string
  value: unknown
  pct: unknown
  min?: number
  onSet: (v: number) => void
}) {
  const min = props.min ?? 0
  return (
    <box class="qs-row" spacing={12}>
      <label class="qs-icon" label={props.icon} />
      <slider
        hexpand
        class="qs-slider"
        min={min}
        max={1}
        step={0.05}
        value={props.value}
        onDragged={(self: Astal.Slider) => props.onSet(self.value)}
        onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, v: number) => {
          props.onSet(Math.max(min, Math.min(1, v)))
          return false
        }}
      />
      <label class="qs-pct" label={props.pct} />
    </box>
  )
}

// Brightness slider: real backlight via brightnessctl when a device exists
// (laptops), otherwise a software dim overlay (desktops / external monitors).
function BrightnessControl() {
  // Scope to real backlight devices only — otherwise brightnessctl falls back to
  // keyboard LEDs on machines without a backlight.
  let max = 0
  try {
    max = Number(exec(["brightnessctl", "-c", "backlight", "max"]))
  } catch {
    max = 0
  }

  if (max && !Number.isNaN(max)) {
    const level = createPoll("0", 2000, ["brightnessctl", "-c", "backlight", "get"]).as(
      (out) => Number(out) / max,
    )
    return (
      <SliderRow
        icon="󰃟"
        min={0.05}
        value={level}
        pct={level.as((v) => `${Math.round(v * 100)}%`)}
        onSet={(v) =>
          execAsync([
            "brightnessctl",
            "-c",
            "backlight",
            "set",
            `${Math.max(1, Math.round(v * 100))}%`,
          ]).catch(() => {})
        }
      />
    )
  }

  // No hardware backlight → drive the software dim overlay instead.
  return (
    <SliderRow
      icon="󰃟"
      min={MIN_SOFT_BRIGHT}
      value={softBright}
      pct={softBright.as((v) => `${Math.round(v * 100)}%`)}
      onSet={(v) => setSoftBright(Math.max(MIN_SOFT_BRIGHT, Math.min(1, v)))}
    />
  )
}

// Fullscreen, click-through black overlay for software dimming. Opacity is the
// complement of `softBright`; hidden entirely at full brightness. One instance
// is created per monitor so every screen dims together.
function DimOverlay(gdkmonitor: Gdk.Monitor, index: number) {
  return (
    <window
      name={`dim-${index}`}
      namespace="dim"
      application={app}
      gdkmonitor={gdkmonitor}
      css="background-color: transparent;"
      visible={softBright.as((b) => b < 0.999)}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.OVERLAY}
      $={(self: Astal.Window) => Astal.widget_set_click_through(self, true)}
    >
      <box
        hexpand
        vexpand
        css={softBright.as((b) => `background-color: rgba(0,0,0,${1 - b});`)}
      />
    </window>
  )
}

// Network status row — reflects the primary connection (wired/Wi-Fi) and opens
// full network settings on click. Shows for any connection type.
function NetworkRow() {
  const network = AstalNetwork.get_default?.()
  if (!network) return <box />
  const primary = createBinding(network, "primary")
  const connectivity = createBinding(network, "connectivity")
  const icon = primary.as((p) =>
    p === AstalNetwork.Primary.WIRED ? "󰈀" : "󰤨",
  )
  const status = connectivity.as((c) =>
    c === AstalNetwork.Connectivity.FULL
      ? "Connected"
      : c === AstalNetwork.Connectivity.LIMITED
        ? "Limited"
        : "Offline",
  )
  return (
    <button
      class="qs-toggle"
      onClicked={() => execAsync(["nm-connection-editor"]).catch(() => {})}
    >
      <box spacing={12}>
        <label class="qs-icon" label={icon} />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
          <label class="qs-label" xalign={0} label="Network" />
          <label class="qs-sub" xalign={0} label={status} />
        </box>
      </box>
    </button>
  )
}

// Bluetooth on/off toggle (renders only when an adapter is present).
function BluetoothToggle() {
  const bt = AstalBluetooth.get_default?.()
  const adapter = bt?.adapter
  if (!bt || !adapter) return <box />
  const powered = createBinding(adapter, "powered")
  return (
    <button
      class={powered.as((on) => (on ? "qs-toggle active" : "qs-toggle"))}
      onClicked={() => bt.toggle()}
    >
      <box spacing={12}>
        <label class="qs-icon" label="󰂯" />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
          <label class="qs-label" xalign={0} label="Bluetooth" />
          <label class="qs-sub" xalign={0} label={powered.as((on) => (on ? "On" : "Off"))} />
        </box>
      </box>
    </button>
  )
}

// Session actions — power off, restart, log out. Logout exits Hyprland, mirroring
// the `Super+Shift+E` bind; poweroff/reboot go through systemd.
function PowerControls() {
  const actions: { icon: string; label: string; cmd: string[] }[] = [
    { icon: "󰐥", label: "Power off", cmd: ["systemctl", "poweroff"] },
    { icon: "󰜉", label: "Restart", cmd: ["systemctl", "reboot"] },
    { icon: "󰍃", label: "Log out", cmd: ["hyprctl", "dispatch", "exit"] },
  ]
  return (
    <box class="power-row" homogeneous spacing={10}>
      {actions.map((a) => (
        <button
          class="power-btn"
          tooltipText={a.label}
          onClicked={() => execAsync(a.cmd).catch(() => {})}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label class="power-icon" label={a.icon} />
            <label class="power-label" label={a.label} />
          </box>
        </button>
      ))}
    </box>
  )
}

// Left-edge control center. Hidden until toggled: `ags toggle sidebar`.
function Sidebar() {
  return (
    <window
      name="sidebar"
      class="sidebar"
      application={app}
      visible={false}
      anchor={LEFT | TOP | BOTTOM}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      keymode={Astal.Keymode.ON_DEMAND}
      layer={Astal.Layer.OVERLAY}
      marginTop={8}
      marginBottom={8}
      marginLeft={8}
      $={(self: Astal.Window) =>
        self.connect("notify::visible", () => setClockMode(self.visible))
      }
    >
      <box orientation={Gtk.Orientation.VERTICAL} class="sidebar-content" spacing={16}>
        <label class="title" xalign={0} label="Control Center" />
        <Calendar />
        <box orientation={Gtk.Orientation.VERTICAL} class="quick-settings" spacing={10}>
          <NetworkRow />
          <BluetoothToggle />
          <BrightnessControl />
          <VolumeControl />
        </box>
        <PowerControls />
      </box>
    </window>
  )
}

app.start({
  instanceName: "ags",
  css: style,
  main() {
    setClockMode(false) // sidebar starts hidden → bar clock shows the time
    Sidebar()
    app.get_monitors().forEach((m, i) => DimOverlay(m, i))
  },
})
