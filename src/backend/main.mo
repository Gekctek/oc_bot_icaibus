import HttpTypes "mo:http-types";
import Publish "./commands/publish";
import SdkTypes "./sdk/types";
import SdkHttp "./sdk/http";

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
      case (#command(commandAction)) switch (commandAction.command.name) {
        case ("publish") await* Publish.execute(commandAction.command.args);
        case (_) #badRequest(#commandNotFound);
      };
      case (#apiKey(apiKeyAction)) switch (apiKeyAction.scope) {
        // TODO
        case (_) #badRequest(#commandNotFound);
      };
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
