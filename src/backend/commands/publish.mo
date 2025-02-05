import SdkTypes "../sdk/types";

module {

    public func execute(_ : [SdkTypes.CommandArg]) : async* SdkTypes.CommandResponse {
        #success({ message = null });
    };

    public func getSchema() : SdkTypes.SlashCommand {
        {
            name = "publish";
            placeholder = ?"TODOZ";
            description = "Publish message to ICaiBus";
            params = [{
                name = "help";
                description = "Get help";
                placeholder = null;
                required = false;
                paramType = #booleanParam;
            }];
            permissions = {
                community = [];
                chat = [];
                message = [#text];
            };
        };
    };
};
