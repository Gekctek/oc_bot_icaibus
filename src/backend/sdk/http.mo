import HttpTypes "mo:http-types";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Json "mo:json";
import SdkTypes "./types";
import SdkSerializer "./serializer";

module {

    public class HttpHandler(botSchema : SdkTypes.BotSchema, execute_command : SdkTypes.BotActionByCommand -> async* SdkTypes.CommandResponse) {
        public func http_request(request : HttpTypes.Request) : HttpTypes.Response {
            if (request.method == "GET") {
                let jsonObj = SdkSerializer.serializeBotSchema(botSchema);
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
                    let commandResponse = switch (SdkSerializer.deserializeCommand(request.body)) {
                        case (null) #badRequest(#accessTokenInvalid); // TODO proper error?
                        case (?command) await* execute_command(command);
                    };
                    let (statusCode, response) : (Nat16, Json.JSON) = switch (commandResponse) {
                        case (#success(success)) (200, SdkSerializer.serializeSuccess(success));
                        case (#badRequest(badRequest)) (400, SdkSerializer.serializeBadRequest(badRequest));
                        case (#internalError(error)) (500, SdkSerializer.serializeInternalError(error));
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

};
