import HttpTypes "mo:http-types";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Json "mo:json";
import Publish "./commands/publish";
import SdkTypes "./sdk/types";
import SdkSerializer "./sdk/serializer";
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

  private func execute_command(action : SdkTypes.BotActionByCommand) : async* SdkTypes.CommandResponse {
    switch (action.command.name) {
      case ("publish") await* Publish.execute(action.command.args);
      case (_) #badRequest(#commandNotFound);
    };
  };

  let handler = SdkHttp.HttpHandler(botSchema, execute_command);

  public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
    handler.http_request(request);
  };

  public func http_request_update(request : HttpTypes.UpdateRequest) : async HttpTypes.UpdateResponse {
    handler.http_request_update(request);
  };
};
