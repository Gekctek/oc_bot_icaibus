import Json "mo:json";
import SdkTypes "../sdk/types";

module {

    public func execute(_ : [SdkTypes.CommandArg]) : async* SdkTypes.CommandResponse {
        #success({ message = null });
    };

    public func getSchema() : Json.JSON {
        #Object([("name", #String("publish")), ("description", #String("Publish message to ICaiBus")), ("placeholder", #String("TODO")), ("params", #Array([#Object([("name", #String("help")), ("description", #String("Get help")), ("type", #String("boolean"))])])), ("permissions", #Object([("community", #Array([])), ("chat", #Array([])), ("message", #Array([#String("Text")]))]))]);
    };
};
