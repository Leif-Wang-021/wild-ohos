
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { MethodsPlugin } from '../plugin/MethodsPlugin';

export default class EntryAbility extends FlutterAbility {
  private methodsPlugin?: MethodsPlugin;

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.methodsPlugin = new MethodsPlugin(flutterEngine, this.context)
  }
}
