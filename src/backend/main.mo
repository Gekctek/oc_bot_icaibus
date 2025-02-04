import HttpTypes "mo:http-types";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Json "mo:json";
import Publish "./commands/publish";
import SdkTypes "./sdk/types";
import SdkSerializer "./sdk/serializer";

actor {

  public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
    if (request.method == "GET") {
      let jsonObj : Json.JSON = #Object([
        ("description", #String("ICaiBus Bot")),
        ("commands", #Array([Publish.getSchema()])),
        ("autonomous_config", #Object([("community", #Array([])), ("chat", #Array([])), ("message", #Array([#String("Text")]))])),
      ]);
      let jsonBytes = Text.encodeUtf8(Json.stringify(jsonObj, null));
      return {
        status_code = 200;
        headers = [("Content-Type", "application/json")];
        body = jsonBytes;
        streaming_strategy = null;
        upgrade = null;
      };
    };
    if (request.method == "POST") {
      // Upgrade request on POST
      return {
        status_code = 200;
        headers = [];
        body = Blob.fromArray([]);
        streaming_strategy = null;
        upgrade = ?true;
      };
    };
    // Not found catch all
    getNotFoundResponse();
  };

  public func http_request_update(request : HttpTypes.UpdateRequest) : async HttpTypes.UpdateResponse {

    if (request.method == "POST") {
      // TODO query string (use path not url)
      if (request.url == "/execute_command") {
        let (statusCode, response) : (Nat16, Json.JSON) = switch (SdkSerializer.deserializeCommand(request.body)) {
          case (null) (400, #Object([("error", #String("Invalid body"))]));
          case (?command) switch (await* execute_command(command)) {
            case (#success(success)) (200, SdkSerializer.serializeSuccess(success));
            case (#badRequest(badRequest)) (400, SdkSerializer.serializeBadRequest(badRequest));
            case (#internalError(error)) (500, SdkSerializer.serializeInternalError(error));
          };
        };
        let jsonBytes = Text.encodeUtf8(Json.stringify(response, null));
        return {
          status_code = statusCode;
          headers = [("Content-Type", "application/json")];
          body = jsonBytes;
          streaming_strategy = null;
          upgrade = null;
        };
      };
    };

    // Not found catch all
    getNotFoundResponse();
  };

  private func execute_command(action : SdkTypes.BotActionByCommand) : async* SdkTypes.CommandResponse {
    switch (action.command.name) {
      case ("publish") await* Publish.execute(action.command.args);
      case (_) #badRequest(#commandNotFound);
    };
  };

  private func getNotFoundResponse() : HttpTypes.Response {
    {
      status_code = 404;
      headers = [];
      body = Blob.fromArray([]);
      streaming_strategy = null;
      upgrade = null;
    };
  };
};
