System Architecture Diagram
===========================

Overview
--------
The HoldOn platform combines mobile sensing, foreground/background services, and cloud-free analytics to deliver a multi-layered theft-prevention experience. The architecture is organized into defensive layers that operate from hardware integration up to user-facing controls.

Layers of Prevention and Defence
--------------------------------
1. **Hardware & Sensors Layer**
   - Accelerometer, gyroscope, and ambient light sensors feed raw motion and light data.
   - Power management components keep wake locks and sensor sampling active during monitoring.

2. **Native Services Layer (Android Foreground Service)**
   - AntiTheftService continuously aggregates sensor readings even when the app is backgrounded.
   - Device admin APIs enable secure screen locking and enforce alarm volume policies.
   - Pocket protocol uses the light sensor to detect device removal from pockets and starts the configurable grace timer (3‑10 seconds).

3. **Bridging & Event Dispatch Layer**
   - Method Channels (`holdon.device_lock`) expose native controls (start/stop service, pocket timer configuration, alarm volume).
   - Event Channels (`holdon.service_events`, `holdon.volume_monitor`) broadcast sensor and timer events back to Flutter.
   - SharedPreferences persist the pocket timer configuration and other native settings.

4. **Flutter Service Layer**
   - `SecurityService` orchestrates activation, deactivation, and alarm callbacks.
   - `AntiTheftManager` maintains subscriptions to native streams, pushes configuration updates (grace timer) and forwards alarms to the UI.

5. **Application State & Configuration Layer**
   - `AppState` propagates localization and high-level app settings.
   - `SettingsScreen` exposes UI controls for notifications, vibration, localisation, and the pocket timer slider (3‑10 seconds), synchronising directly with `SecurityService`.
   - L10n resources localise all user-facing strings, including zone creation and timer labels.

6. **UI & Interaction Layer**
   - `MapScreen` renders hotspots and custom zones, enabling long-press creation with localized forms.
   - `SecurityScreen` provides activation toggles, alarm status, and quick access to restart or lock controls.

Hardware Integration Touchpoints
--------------------------------
- **Sensors**: Accelerometer, gyroscope, light sensor, and volume hardware feed real-time telemetry into AntiTheftService.
- **Audio**: System audio streams are forced to max volume during alarms to ensure audibility.
- **Power Management**: Wake locks prevent CPU sleep while monitoring is active; device admin access allows immediate lock when theft is detected.
- **Notifications & Alarm Hardware**: Foreground service notifications keep the process resilient; vibration and speaker hardware are triggered by `SecurityService` callbacks.

Operational Flow Highlights
---------------------------
1. **Activation**: User enables monitoring; Flutter requests native service start with current grace timer value.
2. **Pocket Detection**: Light sensor triggers pocket protocol; timer counts down with configured delay.
3. **Alarm**: Timer expiry or other sensor thresholds trigger alarms, locking the screen and playing the siren.
4. **Settings Update**: Adjusting the pocket timer slider persists the new value, updates the running service, and changes behaviour immediately.
5. **Geofencing**: Custom zones created via the map are stored locally, broadcast via events, and synced to both standard and optimized geofencing services.

Flow Diagram
------------
```
         ┌────────────────┐
         │ User Activates │
         │  Security Mode │
         └──────┬─────────┘
                │
                ▼
        ┌─────────────────┐         ┌───────────────────────────┐
        │ SecurityService │◄────────┤ SettingsScreen (timer 3-10 │
        │  (Flutter)      │ update  │  seconds slider)           │
        └──────┬──────────┘         └──────────┬────────────────┘
               │ startForegroundService         │
               ▼                                │
      ┌────────────────────┐                    │
      │ AntiTheftManager   │ pushes config      │
      │  (Flutter)         │────────────────────┘
      └──────┬─────────────┘
             │ MethodChannel (device_lock)
             ▼
  ┌───────────────────────────┐
  │ AntiTheftService (Android)│
  │ - Sensors (acc/gyro/light)│
  │ - Pocket timer (CountDown)│
  └──────┬─────────────┬──────┘
         │EventChannel  │MethodChannel
         ▼              ▼
 ┌────────────────┐   ┌──────────────────────────┐
 │ UI Screens     │   │ SharedPreferences        │
 │ (Map, Security,│   │ (pocket timer persists)  │
 │  Zones)        │   └──────────┬──────────────┘
 └────────────────┘              │
         ▲                       │
         │ geofence events       │
         │                       │
         └────────────┬──────────┘
                      ▼
            ┌──────────────────┐
            │ Alarm Hardware   │
            │ (Audio, Vibration│
            │  Device Lock)    │
            └──────────────────┘
```

Pocket Removal Detection Flow
-----------------------------
```
 t0          t1          t2          t3
 │           │           │           │
 │           │           │           │
 ▼           ▼           ▼           ▼

 ┌───────────┬───────────┬───────────┬──────────── Lux (sensor)
 │           │           │           │
 │ Pocket    │ Pocket    │ Removal   │ Outside pocket
 │ covered   │ armed     │ detected  │ grace timer running
 │ (≈0 lux)  │ (≈0 lux)  │ (>threshold)
 └───────────┴───────────┴───────────┴───────────── time →

 ┌───────────────────────────────────────────────────────────────┐
 │ AntiTheftService state                                        │
 │ ──────────────┬──────────────┬──────────────────────┬─────────│
 │ protocol idle │ protocol armed│ grace countdown (3-10 s)      │
 │               │              │ (cancel if user unlocks)       │
 └───────────────┴──────────────┴──────────────────────┴─────────┘

 ┌───────────────────────────────────────────────────────────────┐
 │ Events broadcast via ServiceEventManager                      │
 │ pocket_protocol_activated → pocket_protocol_triggered →       │
 │ pocket_timer_started → (tick updates) → pocket_timer_finished │
 └───────────────────────────────────────────────────────────────┘
```

This document captures the conceptual architecture. For implementation details, refer to the respective Flutter and native source files.

