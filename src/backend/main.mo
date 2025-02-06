import HttpTypes "mo:http-types";
import Publish "./commands/publish";
import SdkTypes "mo:openchat-bot-sdk/types";
import SdkHttp "mo:openchat-bot-sdk/http";

actor {

  let botSchema : SdkTypes.BotSchema = {
    description = "ICaiBus Bot";
    commands = [Publish.getSchema()];
    autonomousConfig = ?{
      permissions = ?{
        community = [];
        chat = [];
        message = [#text];
      };
    };
  };

  private func execute(action : SdkTypes.BotAction) : async* SdkTypes.CommandResponse {
    switch (action) {
      case (#command(commandAction)) await* executeCommandAction(commandAction);
      case (#apiKey(apiKeyAction)) await* executeApiKeyAction(apiKeyAction);
    };
  };

  private func executeCommandAction(action : SdkTypes.BotActionByCommand) : async* SdkTypes.CommandResponse {
    let messageId = switch (action.scope) {
      case (#chat(chatDetails)) ?chatDetails.messageId;
      case (#community(_)) null;
    };
    switch (action.command.name) {
      case ("publish") await* Publish.execute(messageId, action.command.args);
      case (_) #badRequest(#commandNotFound);
    };
  };

  private func executeApiKeyAction(action : SdkTypes.BotActionByApiKey) : async* SdkTypes.CommandResponse {
    switch (action.scope) {
      // TODO
      case (_) #badRequest(#commandNotFound);
    };
  };

  let handler = SdkHttp.HttpHandler(botSchema, execute);

  public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
    handler.http_request(request);
  };

  public func http_request_update(request : HttpTypes.UpdateRequest) : async HttpTypes.UpdateResponse {
    await* handler.http_request_update(request);
  };
};
