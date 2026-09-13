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

const MIN_SOFT_BRIGHT = 0.3
const [softBright, setSoftBright] = createState(1)

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

const dayKey = (y: number, m: number, d: number) => `${y}-${m}-${d}`

function monthMatrix(offset: number): { title: string; weeks: Cell[][] } {
  const now = new Date()
  const first = new Date(now.getFullYear(), now.getMonth() + offset, 1)
  const month = first.getMonth()
  const startDow = first.getDay()

  const start = new Date(first)
  start.setDate(1 - startDow)

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
                  <button
                    class="cal-nav"
                    canFocus={false}
                    onClicked={() => setOffset(off - 1)}
                  >
                    <label label="‹" />
                  </button>
                  <button
                    class="cal-title-btn"
                    hexpand
                    canFocus={false}
                    tooltipText="Jump to today"
                    onClicked={jumpToToday}
                  >
                    <label class="cal-title" label={title} />
                  </button>
                  <button
                    class="cal-nav"
                    canFocus={false}
                    onClicked={() => setOffset(off + 1)}
                  >
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
                          canFocus={false}
                          onClicked={() => setSelected(key)}
                          onButtonPressEvent={(_self: Gtk.Button, event: Gdk.EventButton) => {
                            if (event.type === Gdk.EventType.DOUBLE_BUTTON_PRESS) {
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

let volumeSlider: Astal.Slider | null = null

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
        $={(self: Astal.Slider) => (volumeSlider = self)}
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

function BrightnessControl() {
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

type SessionAction = { label: string; cmd: string[] }
const [pendingAction, setPendingAction] = createState<SessionAction | null>(null)
const [confirmChoice, setConfirmChoice] = createState<"yes" | "no">("yes")

function askConfirm(action: SessionAction) {
  setConfirmChoice("yes")
  // Dismiss the control center so the modal sits cleanly over the whole screen
  // rather than looking tucked beside the panel.
  app.get_window("sidebar")?.hide()
  setPendingAction(action)
}
function cancelConfirm() {
  setPendingAction(null)
}
function runConfirmed() {
  const action = pendingAction.get()
  setPendingAction(null)
  if (action) execAsync(action.cmd).catch(() => {})
}
function activateChoice() {
  if (confirmChoice.get() === "yes") runConfirmed()
  else cancelConfirm()
}

// Full-screen dim backdrop, one per monitor, shown while a confirmation is pending.
function ConfirmBackdrop(gdkmonitor: Gdk.Monitor, index: number) {
  return (
    <window
      name={`confirm-dim-${index}`}
      namespace="confirm-dim"
      application={app}
      gdkmonitor={gdkmonitor}
      visible={pendingAction.as((a) => a !== null)}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.OVERLAY}
      css="background-color: transparent;"
    >
      <box class="confirm-backdrop" hexpand vexpand />
    </window>
  )
}

function ConfirmDialog() {
  return (
    <window
      name="confirm"
      class="confirm"
      namespace="confirm"
      application={app}
      visible={pendingAction.as((a) => a !== null)}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.EXCLUSIVE}
      layer={Astal.Layer.OVERLAY}
      onKeyPressEvent={(_self: Astal.Window, event: Gdk.EventKey) => {
        const gk: any = (event as any).get_keyval?.()
        const keyval =
          typeof gk === "number"
            ? gk
            : Array.isArray(gk)
              ? gk[1]
              : // eslint-disable-next-line @typescript-eslint/no-explicit-any
                (event as any).keyval
        switch (keyval) {
          case Gdk.KEY_Left:
            setConfirmChoice("yes")
            return true
          case Gdk.KEY_Right:
            setConfirmChoice("no")
            return true
          case Gdk.KEY_Up:
          case Gdk.KEY_Down:
          case Gdk.KEY_Tab:
          case Gdk.KEY_ISO_Left_Tab:
            setConfirmChoice(confirmChoice.get() === "yes" ? "no" : "yes")
            return true
          case Gdk.KEY_Return:
          case Gdk.KEY_KP_Enter:
            activateChoice()
            return true
          case Gdk.KEY_Escape:
            cancelConfirm()
            return true
          default:
            return false
        }
      }}
    >
      <box hexpand vexpand>
        <box
          class="confirm-box"
          orientation={Gtk.Orientation.VERTICAL}
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          spacing={18}
        >
          <label
            class="confirm-title"
            label={pendingAction.as((a) => (a ? a.label : ""))}
          />
          <label class="confirm-sub" label="Are you sure?" />
          <box class="confirm-actions" homogeneous spacing={12}>
            <button
              class={confirmChoice.as((c) =>
                c === "yes" ? "confirm-btn selected" : "confirm-btn",
              )}
              onClicked={runConfirmed}
            >
              <label label="Yes" />
            </button>
            <button
              class={confirmChoice.as((c) =>
                c === "no" ? "confirm-btn selected" : "confirm-btn",
              )}
              onClicked={cancelConfirm}
            >
              <label label="No" />
            </button>
          </box>
        </box>
      </box>
    </window>
  )
}

// Session actions
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
          onClicked={() => askConfirm({ label: a.label, cmd: a.cmd })}
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

function Sidebar() {
  return (
    <window
      name="sidebar"
      class="sidebar"
      application={app}
      visible={false}
      anchor={LEFT | TOP | BOTTOM}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      keymode={Astal.Keymode.EXCLUSIVE}
      layer={Astal.Layer.OVERLAY}
      marginTop={8}
      marginBottom={8}
      marginLeft={8}
      onKeyPressEvent={(self: Astal.Window, event: Gdk.EventKey) => {
        const gk: any = (event as any).get_keyval?.()
        const keyval =
          typeof gk === "number"
            ? gk
            : Array.isArray(gk)
              ? gk[1]
              : // eslint-disable-next-line @typescript-eslint/no-explicit-any
                (event as any).keyval
        switch (keyval) {
          case Gdk.KEY_Down:
            self.child_focus(Gtk.DirectionType.TAB_FORWARD)
            return true
          case Gdk.KEY_Up:
            self.child_focus(Gtk.DirectionType.TAB_BACKWARD)
            return true
          case Gdk.KEY_Escape:
            self.hide()
            return true
          default:
            return false
        }
      }}
      $={(self: Astal.Window) =>
        self.connect("notify::visible", () => {
          setClockMode(self.visible)
          if (self.visible)
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
              if (volumeSlider) volumeSlider.grab_focus()
              else self.child_focus(Gtk.DirectionType.TAB_FORWARD)
              return GLib.SOURCE_REMOVE
            })
        })
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
    setClockMode(false)
    Sidebar()
    app.get_monitors().forEach((m, i) => ConfirmBackdrop(m, i))
    ConfirmDialog()
    app.get_monitors().forEach((m, i) => DimOverlay(m, i))
  },
})
