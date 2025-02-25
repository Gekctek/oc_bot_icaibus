import Subscriber "mo:icrc72-subscriber-mo";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Sdk "mo:openchat-bot-sdk";
import Debug "mo:base/Debug";
import Result "mo:base/Result";

module {

    public type Args = {
        to : Text;
    };

    public func execute(messageId : ?Sdk.MessageId, args : Args, subscriber : Subscriber.Subscriber) : async* Sdk.CommandResponse {

        let subscribeResult = await* subscriber.subscribe([{
            namespace = "com.icp.org.trx_stream";
            config = [
                (Subscriber.CONST.subscription.filter, #Text("$.to == " # args.to)), // TODO validate is address
            ];
            memo = null;
            listener = #Async(onNotification);
        }]);
        switch (subscribeResult[0]) {
            case (?#Ok(_)) ();
            case (?#Err(err)) {
                let message = "Error subscribing: " # debug_show (err);
                Debug.print(message);
                return #internalError(#canisterError(#other(message)));
            };
            case (null) {
                Debug.print("Nothing");
                return #internalError(#canisterError(#other("Nothing")));
            };
        };

        let messageOrNull : ?Sdk.Message = switch (messageId) {
            case (?id) ?{
                id = id;
                content = #text({
                    text = "Subscrition created";
                });
                finalised = true;
            };
            case (_) null;
        };
        #success({
            message = messageOrNull;
        });
    };

    private func onNotification<system>(event : Subscriber.EventNotification) : async* () {
        Debug.print("Received Event: " # debug_show (event));
        let #Class(data) = event.data else return;
        let trx = data
        |> Array.map<Subscriber.ICRC16Property, Subscriber.ICRC16MapItem>(_, func(x) : Subscriber.ICRC16MapItem { (x.name, x.value) })
        |> _.vals()
        |> Subscriber.Map.fromIter<Text, Subscriber.ICRC16>(_, Subscriber.Map.thash);

        Debug.print(debug_show (trx));
        let ?#Nat(amount) = Subscriber.Map.get<Text, Subscriber.ICRC16>(trx, Subscriber.Map.thash, "amount") else return;
        let ?#Text(from) = Subscriber.Map.get<Text, Subscriber.ICRC16>(trx, Subscriber.Map.thash, "from") else return;
        let ?#Text(spender) = Subscriber.Map.get<Text, Subscriber.ICRC16>(trx, Subscriber.Map.thash, "spender") else return;
        let ?#Nat(ts) = Subscriber.Map.get<Text, Subscriber.ICRC16>(trx, Subscriber.Map.thash, "ts") else return;
        let trxId = switch (Subscriber.Map.get<Text, Subscriber.ICRC16>(trx, Subscriber.Map.thash, "id")) {
            case (?#Nat(val)) val;
            case (_) 0;
        };

        Debug.print("Received Transaction: " # debug_show ((amount, from, spender, ts, trxId)));

        // TODO

    };

    public func getSchema() : Sdk.SlashCommand {
        {
            name = "subscribe";
            placeholder = null;
            description = "Subscribe to ICaiBus";
            params = [{
                name = "to";
                description = "Address to subscribe to";
                placeholder = null;
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

    public func parseArgs(args : [Sdk.CommandArg]) : Result.Result<Args, Sdk.CommandResponse> {
        if (args.size() != 1) {
            Debug.print("Invalid request: Only one argument is allowed");
            return #err(#badRequest(#argsInvalid));
        };
        let toArg = args[0];
        if (toArg.name != "to") {
            Debug.print("Invalid request: Only 'to' argument is allowed");
            return #err(#badRequest(#argsInvalid));
        };

        let #string(to) = toArg.value else {
            Debug.print("Invalid request: Message argument must be a string");
            return #err(#badRequest(#argsInvalid));
        };
        #ok({
            to = to;
        });
    };
};

// shared (deployer) actor class Subscriber<system>(
//     args : ?{
//         orchestrator : Principal;
//         icrc72SubscriberArgs : ?ICRC72Subscriber.InitArgs;
//         icrc75 : ICRC75.InitArgs;
//         ttArgs : ?TT.Args;
//     }
// ) = this {
// module {

// let debug_channel = {
//     var timerTool = true;
//     var icrc72Subscriber = true;
//     var announce = true;
//     var init = true;
// };

// public type DataItemMap = ICRC75Service.DataItemMap;
// public type ManageRequest = ICRC75Service.ManageRequest;
// public type ManageResult = ICRC75Service.ManageResult;
// public type ManageListMembershipRequest = ICRC75Service.ManageListMembershipRequest;
// public type ManageListMembershipRequestItem = ICRC75Service.ManageListMembershipRequestItem;
// public type ManageListMembershipAction = ICRC75Service.ManageListMembershipAction;
// public type ManageListPropertyRequest = ICRC75Service.ManageListPropertyRequest;
// public type ManageListMembershipResponse = ICRC75Service.ManageListMembershipResponse;
// public type ManageListPropertyRequestItem = ICRC75Service.ManageListPropertyRequestItem;
// public type ManageListPropertyResponse = ICRC75Service.ManageListPropertyResponse;
// public type AuthorizedRequestItem = ICRC75Service.AuthorizedRequestItem;
// public type PermissionList = ICRC75Service.PermissionList;
// public type PermissionListItem = ICRC75Service.PermissionListItem;
// public type ListRecord = ICRC75Service.ListRecord;
// public type List = ICRC75.List;
// public type ListItem = ICRC75.ListItem;
// public type Permission = ICRC75.Permission;
// public type Identity = ICRC75.Identity;
// public type ManageResponse = ICRC75Service.ManageResponse;

//default args
// let BTree = ICRC72Subscriber.BTree;
// let Map = ICRC72Subscriber.Map;
// type ICRC16 = ICRC72Subscriber.ICRC16;
// type ICRC16Map = ICRC72Subscriber.ICRC16Map;
// type ICRC16Property = ICRC72Subscriber.ICRC16Property;
// type ICRC16MapItem = ICRC72Subscriber.ICRC16MapItem;

// };
