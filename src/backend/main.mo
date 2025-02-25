import HttpTypes "mo:http-types";
import SubscribeCommand "./commands/subscribe";
import Sdk "mo:openchat-bot-sdk";
import Text "mo:base/Text";
import Subscriber "mo:icrc72-subscriber-mo";
import SubscriberService "mo:icrc72-subscriber-mo/service";
import Principal "mo:base/Principal";
import TimerTool "mo:timer-tool";
import CommandHandler "CommandHandler";
import SubscriptionUtil "SubscriptionUtil";

type ActorArgs = {
  orchestratorPrincipal : Principal;
};
shared ({ caller = deployer }) actor class Actor(args : ActorArgs) = this {

  let botSchema : Sdk.BotSchema = {
    description = "ICaiBus Bot";
    commands = [SubscribeCommand.getSchema()];
    autonomousConfig = ?{
      permissions = ?{
        community = [];
        chat = [];
        message = [#text];
      };
    };
  };

  stable var owner : Principal = deployer;

  stable var subscriberStableData : Subscriber.State = Subscriber.Migration.migration.initialState;
  stable var timerStableData : TimerTool.State = TimerTool.Migration.migration.initialState;

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

  let commandHandler = CommandHandler.CommandHandler(subscriberFactory);

  let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE5GaOVUjuWn59a8Bp79694D5KClL77iirARZNAzxLY2U4HYcEbU+PtOfM8/00Ovo+2uSbFhsCQPw+ijM3pf6OOQ=="); // TODO handle error

  let handler = Sdk.HttpHandler(botSchema, commandHandler.execute, openChatPublicKey);

  public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
    handler.http_request(request);
  };

  public func http_request_update(request : HttpTypes.UpdateRequest) : async HttpTypes.UpdateResponse {
    await* handler.http_request_update(request);
  };

  public shared (msg) func icrc72_handle_notification(items : [SubscriberService.EventNotification]) : () {
    return await* subscriberFactory().icrc72_handle_notification(msg.caller, items);
  };

  public query (msg) func get_stats() : async Subscriber.Stats {
    return subscriberFactory().stats();
  };

};
