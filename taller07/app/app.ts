import { Application } from "@nativescript/core";

let appWasStopped = false;

function log(message: string): void {
  console.log(`[Lifecycle] ${message}`);
}

function setupLifecycleLogs(): void {
  if (Application.android) {
    Application.android.on(Application.AndroidApplication.activityCreatedEvent, () => {
      log("onCreate");
    });

    Application.android.on(Application.AndroidApplication.activityStartedEvent, () => {
      if (appWasStopped) {
        log("onRestart");
        appWasStopped = false;
      }
      log("onStart");
    });

    Application.android.on(Application.AndroidApplication.activityResumedEvent, () => {
      log("onResume");
    });

    Application.android.on(Application.AndroidApplication.activityPausedEvent, () => {
      log("onPause");
    });

    Application.android.on(Application.AndroidApplication.activityStoppedEvent, () => {
      appWasStopped = true;
      log("onStop");
    });

    Application.android.on(Application.AndroidApplication.activityDestroyedEvent, () => {
      log("onDestroy");
    });
  }

  Application.on(Application.suspendEvent, () => {
    log("Application suspend");
  });

  Application.on(Application.resumeEvent, () => {
    log("Application resume");
  });
}

setupLifecycleLogs();
Application.run({ moduleName: "app-root" });
