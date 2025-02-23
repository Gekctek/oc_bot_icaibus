import HttpTypes "mo:http-types";
import Publish "./commands/publish";
import SdkTypes "mo:openchat-bot-sdk/Types";
import SdkHttp "mo:openchat-bot-sdk/HTTP";
import Text "mo:base/Text";

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
      case (_) #badRequest(#commandNotFound);
    };
  };

  let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE5GaOVUjuWn59a8Bp79694D5KClL77iirARZNAzxLY2U4HYcEbU+PtOfM8/00Ovo+2uSbFhsCQPw+ijM3pf6OOQ=="); // TODO handle error

  let handler = SdkHttp.HttpHandler(botSchema, execute, openChatPublicKey);

  public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
    handler.http_request(request);
  };

  public func http_request_update(request : HttpTypes.UpdateRequest) : async HttpTypes.UpdateResponse {
    await* handler.http_request_update(request);
  };

};
