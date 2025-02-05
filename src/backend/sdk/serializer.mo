import Json "mo:json";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import SdkTypes "./types";
import IterTools "mo:itertools/Iter";

module {

    public func serializeBotSchema(botSchema : SdkTypes.BotSchema) : Json.Json {
        let autonomousConfigJson = switch (botSchema.autonomousConfig) {
            case (null) #null_;
            case (?config) serializeAutonomousConfig(config);
        };

        #object_([
            ("description", #string(botSchema.description)),
            ("commands", serializeArrayOfValues(botSchema.commands, serializeSlashCommand)),
            ("autonomous_config", autonomousConfigJson),
        ]);
    };

    private func serializeAutonomousConfig(config : SdkTypes.AutonomousConfig) : Json.Json {
        let permissionsJson = switch (config.permissions) {
            case (null) #null_;
            case (?permissions) serializeBotPermissions(permissions);
        };

        #object_([("permissions", permissionsJson)]);
    };

    private func serializeSlashCommand(command : SdkTypes.SlashCommand) : Json.Json {
        let placeholderJson = switch (command.placeholder) {
            case (null) #null_;
            case (?placeholder) #string(placeholder);
        };

        #object_([
            ("name", #string(command.name)),
            ("description", #string(command.description)),
            ("placeholder", placeholderJson),
            ("params", serializeArrayOfValues(command.params, serializeSlashCommandParam)),
            ("permissions", serializeBotPermissions(command.permissions)),
        ]);
    };

    private func serializeSlashCommandParam(param : SdkTypes.SlashCommandParam) : Json.Json {
        let placeholderJson = switch (param.placeholder) {
            case (null) #null_;
            case (?placeholder) #string(placeholder);
        };

        #object_([
            ("name", #string(param.name)),
            ("description", #string(param.description)),
            ("placeholder", placeholderJson),
            ("required", #bool(param.required)),
            ("param_type", serializeParamType(param.paramType)),
        ]);
    };

    private func serializeParamType(paramType : SdkTypes.SlashCommandParamType) : Json.Json {
        switch (paramType) {
            case (#userParam) #string("UserParam");
            case (#booleanParam) #string("BooleanParam");
            case (#stringParam(strParam)) #object_([("StringParam", serializeStringParam(strParam))]);
            case (#numberParam(numParam)) #object_([("NumberParam", serializeNumberParam(numParam))]);
        };
    };

    private func serializeStringParam(param : SdkTypes.StringParam) : Json.Json {
        #object_([
            ("min_length", #number(#int(param.minLength))),
            ("max_length", #number(#int(param.maxLength))),
            ("choices", serializeArrayOfValues(param.choices, serializeStringChoice)),
        ]);
    };

    private func serializeNumberParam(param : SdkTypes.NumberParam) : Json.Json {
        #object_([
            ("min_length", #number(#int(param.minLength))),
            ("max_length", #number(#int(param.maxLength))),
            ("choices", serializeArrayOfValues(param.choices, serializeNumberChoice)),
        ]);
    };

    private func serializeStringChoice(choice : SdkTypes.StringChoice) : Json.Json {
        #object_([
            ("name", #string(choice.name)),
            ("value", #string(choice.value)),
        ]);
    };

    private func serializeNumberChoice(choice : SdkTypes.NumberChoice) : Json.Json {
        #object_([
            ("name", #string(choice.name)),
            ("value", #number(#int(choice.value))),
        ]);
    };

    private func serializeBotPermissions(permissions : SdkTypes.BotPermissions) : Json.Json {
        #object_([
            ("community", serializeArrayOfValues(permissions.community, serializeCommunityPermission)),
            ("chat", serializeArrayOfValues(permissions.chat, serializeGroupPermission)),
            ("message", serializeArrayOfValues(permissions.message, serializeMessagePermission)),
        ]);
    };

    private func serializeCommunityPermission(permission : SdkTypes.CommunityPermission) : Json.Json {
        #string(
            switch (permission) {
                case (#changeRoles) "ChangeRoles";
                case (#updateDetails) "UpdateDetails";
                case (#inviteUsers) "InviteUsers";
                case (#removeMembers) "RemoveMembers";
                case (#createPublicChannel) "CreatePublicChannel";
                case (#createPrivateChannel) "CreatePrivateChannel";
                case (#manageUserGroups) "ManageUserGroups";
            }
        );
    };

    private func serializeGroupPermission(permission : SdkTypes.GroupPermission) : Json.Json {
        #string(
            switch (permission) {
                case (#changeRoles) "ChangeRoles";
                case (#updateGroup) "UpdateGroup";
                case (#addMembers) "AddMembers";
                case (#inviteUsers) "InviteUsers";
                case (#removeMembers) "RemoveMembers";
                case (#deleteMessages) "DeleteMessages";
                case (#pinMessages) "PinMessages";
                case (#reactToMessages) "ReactToMessages";
                case (#mentionAllMembers) "MentionAllMembers";
                case (#startVideoCall) "StartVideoCall";
            }
        );
    };

    private func serializeMessagePermission(permission : SdkTypes.MessagePermission) : Json.Json {
        #string(
            switch (permission) {
                case (#text) "Text";
                case (#image) "Image";
                case (#video) "Video";
                case (#audio) "Audio";
                case (#file) "File";
                case (#poll) "Poll";
                case (#crypto) "Crypto";
                case (#giphy) "Giphy";
                case (#prize) "Prize";
                case (#p2pSwap) "P2pSwap";
                case (#videoCall) "VideoCall";
            }
        );
    };

    public func serializeSuccess(success : SdkTypes.SuccessResult) : Json.Json {
        let messageJson = switch (success.message) {
            case (null) #null_;
            case (?message) serializeMessage(message);
        };
        #object_([("message", messageJson)]);
    };

    private func serializeMessage(message : SdkTypes.Message) : Json.Json {
        #object_([
            ("id", #string(message.id)),
            ("content", serializeMessageContent(message.content)),
            ("finalised", #bool(message.finalised)),
        ]);
    };

    private func serializeMessageContent(content : SdkTypes.MessageContent) : Json.Json {
        switch (content) {
            case (#text(text)) serializeTextContent(text);
            case (#image(image)) serializeImageContent(image);
            case (#video(video)) serializeVideoContent(video);
            case (#audio(audio)) serializeAudioContent(audio);
            case (#file(file)) serializeFileContent(file);
            case (#poll(poll)) serializePollContent(poll);
            case (#giphy(giphy)) serializeGiphyContent(giphy);
        };
    };

    private func serializeTextContent(text : SdkTypes.TextContent) : Json.Json {
        #object_([("text", #string(text.text))]);
    };

    private func serializeImageContent(image : SdkTypes.ImageContent) : Json.Json {
        #object_([
            ("width", #number(#int(image.width))),
            ("height", #number(#int(image.height))),
            ("thumbnail_data", #string(image.thumbnailData)),
            (
                "caption",
                serializeNullable<Text>(image.caption, serializeText),
            ),
            ("mime_type", #string(image.mimeType)),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(image.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeVideoContent(video : SdkTypes.VideoContent) : Json.Json {
        #object_([
            ("width", #number(#int(video.width))),
            ("height", #number(#int(video.height))),
            ("thumbnail_data", #string(video.thumbnailData)),
            (
                "caption",
                serializeNullable<Text>(video.caption, serializeText),
            ),
            ("mime_type", #string(video.mimeType)),
            (
                "image_blob_reference",
                serializeNullable<SdkTypes.BlobReference>(video.imageBlobReference, serializeBlobReference),
            ),
            (
                "video_blob_reference",
                serializeNullable<SdkTypes.BlobReference>(video.videoBlobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeAudioContent(audio : SdkTypes.AudioContent) : Json.Json {
        #object_([
            (
                "caption",
                serializeNullable<Text>(audio.caption, serializeText),
            ),
            ("mime_type", #string(audio.mimeType)),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(audio.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeFileContent(file : SdkTypes.FileContent) : Json.Json {
        #object_([
            ("name", #string(file.name)),
            (
                "caption",
                serializeNullable<Text>(file.caption, serializeText),
            ),
            ("mime_type", #string(file.mimeType)),
            ("file_size", #number(#int(file.fileSize))),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(file.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializePollContent(poll : SdkTypes.PollContent) : Json.Json {
        #object_([
            ("config", serializePollConfig(poll.config)),
        ]);
    };

    private func serializePollConfig(pollConfig : SdkTypes.PollConfig) : Json.Json {
        #object_([
            ("text", serializeNullable<Text>(pollConfig.text, serializeText)),
            ("options", serializeArrayOfValues(pollConfig.options, serializeText)),
            (
                "end_date",
                serializeNullable<Nat>(pollConfig.endDate, serializeInt),
            ),
            ("anonymous", #bool(pollConfig.anonymous)),
            ("show_votes_before_end_date", #bool(pollConfig.showVotesBeforeEndDate)),
            ("allow_multiple_votes_per_user", #bool(pollConfig.allowMultipleVotesPerUser)),
            ("allow_user_to_change_vote", #bool(pollConfig.allowUserToChangeVote)),
        ]);
    };

    private func serializeGiphyContent(giphy : SdkTypes.GiphyContent) : Json.Json {
        #object_([
            ("caption", serializeNullable<Text>(giphy.caption, serializeText)),
            ("title", #string(giphy.title)),
            ("desktop", serializeGiphyImageVariant(giphy.desktop)),
            ("mobile", serializeGiphyImageVariant(giphy.mobile)),
        ]);
    };

    private func serializeGiphyImageVariant(giphyImageVariant : SdkTypes.GiphyImageVariant) : Json.Json {
        #object_([
            ("width", #number(#int(giphyImageVariant.width))),
            ("height", #number(#int(giphyImageVariant.height))),
            ("url", #string(giphyImageVariant.url)),
            ("mime_type", #string(giphyImageVariant.mimeType)),
        ]);
    };

    private func serializeText(option : Text) : Json.Json = #string(option);

    private func serializeInt(int : Int) : Json.Json = #number(#int(int));

    private func serializeArrayOfValues<T>(values : [T], serializer : T -> Json.Json) : Json.Json {
        #array(values.vals() |> Iter.map(_, serializer) |> Iter.toArray(_));
    };

    private func serializeBlobReference(blobReference : SdkTypes.BlobReference) : Json.Json {
        #object_([
            ("canister_id", #string(Principal.toText(blobReference.canister))),
            (
                "blob_id",
                #number(#int(blobReference.blobId)),
            ),
        ]);
    };

    private func serializeNullable<T>(value : ?T, serializer : T -> Json.Json) : Json.Json {
        switch (value) {
            case (null) #null_;
            case (?v) serializer(v);
        };
    };

    public func serializeBadRequest(badRequest : SdkTypes.BadRequestResult) : Json.Json {
        switch (badRequest) {
            case (#accessTokenNotFound) #string("AccessTokenNotFound");
            case (#accessTokenInvalid) #string("AccessTokenInvalid");
            case (#accessTokenExpired) #string("AccessTokenExpired");
            case (#commandNotFound) #string("CommandNotFound");
            case (#argsInvalid) #string("ArgsInvalid");
        };
    };

    public func serializeInternalError(error : SdkTypes.InternalErrorResult) : Json.Json {
        switch (error) {
            case (#invalid(invalid)) serializeVariantWithValue("Invalid", #string(invalid));
            case (#canisterError(canisterError)) serializeVariantWithValue("CanisterError", serializeCanisterError(canisterError));
            case (#c2cError((code, message))) serializeVariantWithValue("C2CError", #array([#number(#int(code)), #string(message)]));
        };
    };

    private func serializeCanisterError(canisterError : SdkTypes.CanisterError) : Json.Json {
        switch (canisterError) {
            case (#notAuthorized) #string("NotAuthorized");
            case (#frozen) #string("Frozen");
            case (#other(other)) serializeVariantWithValue("Other", #string(other));
        };
    };

    private func serializeVariantWithValue(variant : Text, value : Json.Json) : Json.Json {
        #object_([(variant, value)]);
    };

    public func deserializeBotActionByCommand(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionByCommand, Text> {
        let (scopeType, scopeTypeValue) = switch (Json.getAsObject(dataJson, "scope")) {
            case (#ok(scopeObj)) scopeObj[0];
            case (#err(e)) return #err("Invalid 'scope' field: " # debug_show (e));
        };
        let scope : SdkTypes.BotActionScope = switch (scopeType) {
            case ("Chat") switch (deserializeBotActionChatDetails(scopeTypeValue)) {
                case (#ok(chat)) #chat(chat);
                case (#err(e)) return #err("Invalid 'Chat' scope value: " # e);
            };
            case ("Community") switch (deserializeBotActionCommunityDetails(scopeTypeValue)) {
                case (#ok(community)) #community(community);
                case (#err(e)) return #err("Invalid 'Community' scope value: " # e);
            };
            case (_) return #err("Invalid 'scope' field variant type: " # scopeType);
        };

        let botApiGateway = switch (getAsPrincipal(dataJson, "bot_api_gateway")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'bot_api_gateway' field: " # debug_show (e));
        };
        let bot = switch (getAsPrincipal(dataJson, "bot")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'bot' field: " # debug_show (e));
        };

        let communityPermissions = switch (Json.getAsArray(dataJson, "granted_permissions.community")) {
            case (#ok(permssions)) switch (deserializeArrayOfValues(permssions, deserializeCommunityPermission)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'granted_permissions.community' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'granted_permissions.community' field: " # debug_show (e));
        };

        let chatPermissions = switch (Json.getAsArray(dataJson, "granted_permissions.chat")) {
            case (#ok(permssions)) switch (deserializeArrayOfValues(permssions, deserializeGroupPermission)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'granted_permissions.chat' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'granted_permissions.chat' field: " # debug_show (e));
        };

        let messagePermissions = switch (Json.getAsArray(dataJson, "granted_permissions.message")) {
            case (#ok(permissions)) switch (deserializeArrayOfValues(permissions, deserializeMessagePermission)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'granted_permissions.message' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'granted_permissions.message' field: " # debug_show (e));
        };

        let grantedPermissions : SdkTypes.BotPermissions = {
            community = communityPermissions;
            chat = chatPermissions;
            message = messagePermissions;
        };
        let commandName = switch (Json.getAsText(dataJson, "command.name")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'command.name' field: " # debug_show (e));
        };
        let commandArgs : [SdkTypes.CommandArg] = switch (Json.getAsArray(dataJson, "command.args")) {
            case (#ok(args)) switch (deserializeArrayOfValues(args, deserializeCommandArg)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'command.args' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'command.args' field: " # debug_show (e));
        };
        let initiator = switch (getAsPrincipal(dataJson, "command.initiator")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'command.initiator' field: " # debug_show (e));
        };
        let command : SdkTypes.Command = {
            name = commandName;
            args = commandArgs;
            initiator = initiator;
        };

        #ok({
            botApiGateway = botApiGateway;
            bot = bot;
            scope = scope;
            grantedPermissions = grantedPermissions;
            command = command;
        });
    };

    public func deserializeBotActionByApiKey(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionByApiKey, Text> {
        // TODO
        Debug.trap("TODO");
    };

    private func deserializeArrayOfValues<T>(json : [Json.Json], deserialize : Json.Json -> Result.Result<T, Text>) : Result.Result<[T], Text> {
        let buffer = Buffer.Buffer<T>(json.size());
        for ((i, val) in IterTools.enumerate(json.vals())) {
            switch (deserialize(val)) {
                case (#ok(v)) buffer.add(v);
                case (#err(e)) return #err("Failed to deserialize array value [" # Nat.toText(i) # "]: " # e);
            };
        };
        #ok(Buffer.toArray(buffer));
    };

    private func deserializeCommandArg(json : Json.Json) : Result.Result<SdkTypes.CommandArg, Text> {
        let ?#string(name) = Json.get(json, "name") else return #err("Missing  'name' string field in CommandArg");
        let ?#object_(valueJsonKeys) = Json.get(json, "value") else return #err("Missing 'value' object field in CommandArg");
        let value : SdkTypes.CommandArgValue = switch (valueJsonKeys[0]) {
            case (("String", stringValue)) {
                switch (Json.getAsText(stringValue, "")) {
                    case (#ok(string)) #string(string);
                    case (#err(e)) return #err("Invalid 'String' value in CommandArg: " # debug_show (e));
                };
            };
            case (_) return #err("Invalid 'value' object field in CommandArg");
        };
        #ok({
            name = name;
            value = value;
        });
    };

    private func deserializeMessagePermission(json : Json.Json) : Result.Result<SdkTypes.MessagePermission, Text> {
        let #string(permissionString) = json else return #err("Invalid message permission, expected string value");

        let permission : SdkTypes.MessagePermission = switch (permissionString) {
            case ("text") #text;
            case ("image") #image;
            case ("video") #video;
            case ("audio") #audio;
            case ("file") #file;
            case ("poll") #poll;
            case ("crypto") #crypto;
            case ("giphy") #giphy;
            case ("prize") #prize;
            case ("p2pSwap") #p2pSwap;
            case ("videoCall") #videoCall;
            case (_) return #err("Invalid message permission: " # permissionString);
        };
        #ok(permission);
    };

    private func deserializeGroupPermission(json : Json.Json) : Result.Result<SdkTypes.GroupPermission, Text> {
        let #string(permissionString) = json else return #err("Invalid group permission, expected string value");

        let permission : SdkTypes.GroupPermission = switch (permissionString) {
            case ("ChangeRoles") #changeRoles;
            case ("UpdateGroup") #updateGroup;
            case ("AddMembers") #addMembers;
            case ("InviteUsers") #inviteUsers;
            case ("RemoveMembers") #removeMembers;
            case ("DeleteMessages") #deleteMessages;
            case ("PinMessages") #pinMessages;
            case ("ReactToMessages") #reactToMessages;
            case ("MentionAllMembers") #mentionAllMembers;
            case ("StartVideoCall") #startVideoCall;
            case (_) return #err("Invalid group permission: " # permissionString);
        };
        #ok(permission);
    };

    private func deserializeCommunityPermission(json : Json.Json) : Result.Result<SdkTypes.CommunityPermission, Text> {
        let #string(permissionString) = json else return #err("Invalid community permission, expected string value");

        let permission : SdkTypes.CommunityPermission = switch (permissionString) {
            case ("ChangeRoles") #changeRoles;
            case ("UpdateDetails") #updateDetails;
            case ("InviteUsers") #inviteUsers;
            case ("RemoveMembers") #removeMembers;
            case ("CreatePublicChannel") #createPublicChannel;
            case ("CreatePrivateChannel") #createPrivateChannel;
            case ("ManageUserGroups") #manageUserGroups;
            case (_) return #err("Invalid community permission: " # permissionString);
        };
        #ok(permission);
    };

    private func deserializeBotActionChatDetails(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionChatDetails, Text> {
        let (chatType, chatTypeValue) = switch (Json.getAsObject(dataJson, "chat")) {
            case (#ok(chatObj)) chatObj[0];
            case (#err(e)) return #err("Invalid 'chat' field: " # debug_show (e));
        };
        let chat : SdkTypes.Chat = switch (chatType) {
            case ("Direct") switch (getAsPrincipal(chatTypeValue, "")) {
                case (#ok(p)) #direct(p);
                case (#err(e)) return #err("Invalid 'Direct' chat value: " # debug_show (e));
            };
            case ("Group") switch (getAsPrincipal(chatTypeValue, "")) {
                case (#ok(p)) #group(p);
                case (#err(e)) return #err("Invalid 'Group' chat value: " # debug_show (e));
            };
            case ("Channel") {
                let channelPrincipal = switch (getAsPrincipal(chatTypeValue, "[0]")) {
                    case (#ok(v)) v;
                    case (#err(e)) return #err("Invalid 'Channel' chat value: " # debug_show (e));
                };
                let channelId = switch (Json.getAsNat(chatTypeValue, "[1]")) {
                    case (#ok(v)) v;
                    case (#err(e)) return #err("Invalid 'Channel' chat value: " # debug_show (e));
                };
                #channel((channelPrincipal, channelId));
            };
            case (_) return #err("Invalid 'chat' field variant type: " # chatType);
        };

        let threadRootMessageIndex = switch (Json.getAsNat(dataJson, "thread_root_message_index")) {
            case (#ok(v)) ?v;
            case (#err(_)) null; // TODO?
        };

        let messageId = switch (Json.getAsText(dataJson, "message_id")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'message_id' field: " # debug_show (e));
        };

        #ok({
            chat = chat;
            threadRootMessageIndex = threadRootMessageIndex;
            messageId = messageId;
        });
    };
    private func deserializeBotActionCommunityDetails(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionCommunityDetails, Text> {
        let communityId = switch (getAsPrincipal(dataJson, "community_id")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'community_id' field: " # debug_show (e));
        };

        #ok({
            communityId = communityId;
        });
    };

    private func getAsPrincipal(json : Json.Json, path : Json.Path) : Result.Result<Principal, { #pathNotFound; #typeMismatch }> {
        switch (Json.getAsText(json, path)) {
            case (#ok(v)) #ok(Principal.fromText(v));
            case (#err(e)) return #err(e);
        };
    };
};
