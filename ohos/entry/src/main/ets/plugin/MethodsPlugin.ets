import { FlutterEngine, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import context from '@ohos.app.ability.common';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';

const CHANNEL_NAME = 'methods';

export class MethodsPlugin {
  private channel: MethodChannel;
  private abilityContext: context.UIAbilityContext;
  private keepScreenOn: boolean = false;

  constructor(engine: FlutterEngine, abilityContext: context.UIAbilityContext) {
    this.abilityContext = abilityContext;
    this.channel = new MethodChannel(engine.getDartExecutor(), CHANNEL_NAME);
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult) => {
        this.handleMethodCall(call, result);
      }
    });
  }

  private handleMethodCall(call: MethodCall, result: MethodResult) {
    const method = call.method;

    switch (method) {
      case 'dataRoot': {
        try {
          const filesDir = this.abilityContext.filesDir;
          result.success(filesDir);
        } catch (e) {
          result.error('ERROR', 'Failed to get data root: ' + e, null);
        }
        break;
      }
      case 'getKeepScreenOn': {
        result.success(this.keepScreenOn);
        break;
      }
      case 'setKeepScreenOn': {
        const keepOn = call.args as boolean;
        this.keepScreenOn = keepOn;
        try {
          window.getLastWindow(this.abilityContext).then((win) => {
            win.setKeepScreenOn(keepOn);
            result.success(null);
          }).catch((e: Error) => {
            result.success(null);
          });
        } catch (e) {
          result.success(null);
        }
        break;
      }
      case 'openUrl': {
        const url = call.args as string;
        try {
          console.info('[WildMethods] openUrl: ' + url);
          const want: Want = {
            action: 'ohos.want.action.viewData',
            uri: url
          };
          this.abilityContext.startAbility(want).then(() => {
            console.info('[WildMethods] startAbility success');
            result.success(true);
          }).catch((e: Error) => {
            console.error('[WildMethods] startAbility failed: ' + e);
            this.abilityContext.openLink(url, {
              appLinkingOnly: false,
              hideFailureTipDialog: false
            }).then(() => {
              console.info('[WildMethods] openLink fallback success');
              result.success(true);
            }).catch((fallbackError: Error) => {
              console.error('[WildMethods] openLink fallback failed: ' + fallbackError);
              result.error('ERROR', 'Failed to open url: ' + e + '; fallback: ' + fallbackError, null);
            });
          });
        } catch (e) {
          result.error('ERROR', 'Failed to open url: ' + e, null);
        }
        break;
      }
      default: {
        result.notImplemented();
      }
    }
  }
}
