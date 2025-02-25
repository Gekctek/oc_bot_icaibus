import Sdk "mo:openchat-bot-sdk";
import SubscribeCommand "./commands/subscribe";
import Subscriber "mo:icrc72-subscriber-mo";

module {
    public class CommandHandler(subscriberFactory : () -> Subscriber.Subscriber) {

        public func execute(action : Sdk.BotAction) : async* Sdk.CommandResponse {
            switch (action) {
                case (#command(commandAction)) await* executeCommandAction(commandAction);
                case (#apiKey(apiKeyAction)) await* executeApiKeyAction(apiKeyAction);
            };
        };

        private func executeCommandAction(action : Sdk.BotActionByCommand) : async* Sdk.CommandResponse {
            let messageId = switch (action.scope) {
                case (#chat(chatDetails)) ?chatDetails.messageId;
                case (#community(_)) null;
            };
            switch (action.command.name) {
                case ("subscribe") {
                    let args = switch (SubscribeCommand.parseArgs(action.command.args)) {
                        case (#ok(args)) args;
                        case (#err(response)) return response;
                    };
                    let subscriber = subscriberFactory();
                    await* SubscribeCommand.execute(messageId, args, subscriber);
                };
                case (_) #badRequest(#commandNotFound);
            };
        };

        private func executeApiKeyAction(action : Sdk.BotActionByApiKey) : async* Sdk.CommandResponse {
            switch (action.scope) {
                case (_) #badRequest(#commandNotFound);
            };
        };
    };
};
