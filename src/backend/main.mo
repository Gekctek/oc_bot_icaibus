import HttpTypes "mo:http-types";
import SubscribeCommand "./commands/subscribe";
import Sdk "mo:openchat-bot-sdk";
import Text "mo:base/Text";
import Subscriber "mo:icrc72-subscriber-mo";
import SubscriberService "mo:icrc72-subscriber-mo/service";
import Principal "mo:base/Principal";
import TimerTool "mo:timer-tool";
import SubscriptionUtil "SubscriptionUtil";

shared ({ caller = deployer }) actor class Actor(
  args : {
    orchestratorPrincipal : Principal;
  }
) = this {

  let botSchema : Sdk.BotSchema = {
    description = "ICaiBus Bot";
    commands = [SubscribeCommand.getSchema()];
    autonomousConfig = ?{
      permissions = ?{
        community = [];
        chat = [];
        message = [#text];
      };
      syncApiKey = true;
    };
  };

  stable var owner : Principal = deployer;

  stable var subscriberStableData : Subscriber.State = Subscriber.Migration.migration.initialState;
  stable var timerStableData : TimerTool.State = TimerTool.Migration.migration.initialState;
  stable var apiKeys : [Text] = [];

  let subscriberFactory = SubscriptionUtil.create<system>(
    Principal.fromActor(this),
    args.orchestratorPrincipal,
    owner,
    timerStableData,
    func(newState : TimerTool.State) {
      timerStableData := newState;
    },
    subscriberStableData,
    func(newState : Subscriber.State) {
      subscriberStableData := newState;
    },
  );

  private func executeCommandAction(context : Sdk.CommandExecutionContext) : async* Sdk.CommandResponse {
    switch (context.command.name) {
      case ("subscribe") {
        await* SubscribeCommand.execute(context, subscriberFactory);
      };
      case (_) #badRequest(#commandNotFound);
    };
  };

  let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEquEHzJr9605Oy796e4z7LKow46DVNUnDOQWavi86vEhRAAfdbVh/Lgmxfi44LPb6S0wnCRm9kI/XdK1DYw2Eaw==");

  let events : Sdk.Events = {
    onCommandAction = ?executeCommandAction;
    onApiKeyAction = null;
  };

  let handler = Sdk.HttpHandler(apiKeys, botSchema, openChatPublicKey, events);

  public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
    handler.http_request(request);
  };

  public func http_request_update(request : HttpTypes.UpdateRequest) : async HttpTypes.UpdateResponse {
    await* handler.http_request_update(request);
  };

  public shared (msg) func icrc72_handle_notification(items : [SubscriberService.EventNotification]) : () {
    return await* subscriberFactory().icrc72_handle_notification(msg.caller, items);
  };

  public query func get_stats() : async Subscriber.Stats {
    return subscriberFactory().stats();
  };

};
