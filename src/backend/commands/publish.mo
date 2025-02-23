import SdkTypes "mo:openchat-bot-sdk/Types";
import Debug "mo:base/Debug";
import Result "mo:base/Result";

module {

    public func execute(messageId : ?SdkTypes.MessageId, args : [SdkTypes.CommandArg]) : async* SdkTypes.CommandResponse {
        let message = switch (parseMessage(args)) {
            case (#ok(message)) message;
            case (#err(response)) return response;
        };

        let messageOrNull : ?SdkTypes.Message = switch (messageId) {
            case (?id) ?{
                id = id;
                content = #text({
                    text = "Message published: " # message;
                });
                finalised = true;
            };
            case (_) null;
        };
        #success({
            message = messageOrNull;
        });
    };

    public func getSchema() : SdkTypes.SlashCommand {
        {
            name = "publish";
            placeholder = ?"Publish a message to ICaiBus";
            description = "Publish message to ICaiBus";
            params = [{
                name = "message";
                description = "Message to publish";
                placeholder = ?"Placeholder for message";
                required = true;
                paramType = #stringParam({
                    choices = [];
                    minLength = 1;
                    maxLength = 100;
                });
            }];
            permissions = {
                community = [];
                chat = [];
                message = [#text];
            };
        };
    };

    private func parseMessage(args : [SdkTypes.CommandArg]) : Result.Result<Text, SdkTypes.CommandResponse> {
        if (args.size() != 1) {
            Debug.print("Invalid request: Only one argument is allowed");
            return #err(#badRequest(#argsInvalid));
        };
        let messageArg = args[0];
        if (messageArg.name != "message") {
            Debug.print("Invalid request: Only message argument is allowed");
            return #err(#badRequest(#argsInvalid));
        };

        let #string(message) = messageArg.value else {
            Debug.print("Invalid request: Message argument must be a string");
            return #err(#badRequest(#argsInvalid));
        };
        #ok(message);
    };
};
