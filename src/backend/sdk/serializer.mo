import Json "mo:json";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import SdkTypes "./types";
import Base64 "mo:base64";

module {

    public func serializeSuccess(success : SdkTypes.SuccessResult) : Json.JSON {
        let messageJson = switch (success.message) {
            case (null) #Null;
            case (?message) serializeMessage(message);
        };
        #Object([("message", messageJson)]);
    };

    private func serializeMessage(message : SdkTypes.Message) : Json.JSON {
        #Object([
            ("id", #String(message.id)),
            ("content", serializeMessageContent(message.content)),
            ("finalised", #Bool(message.finalised)),
        ]);
    };

    private func serializeMessageContent(content : SdkTypes.MessageContent) : Json.JSON {
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

    private func serializeTextContent(text : SdkTypes.TextContent) : Json.JSON {
        #Object([("text", #String(text.text))]);
    };

    private func serializeImageContent(image : SdkTypes.ImageContent) : Json.JSON {
        #Object([
            ("width", #Number(#Int(image.width))),
            ("height", #Number(#Int(image.height))),
            ("thumbnail_data", #String(image.thumbnailData)),
            (
                "caption",
                serializeNullable<Text>(image.caption, serializeText),
            ),
            ("mime_type", #String(image.mimeType)),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(image.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeVideoContent(video : SdkTypes.VideoContent) : Json.JSON {
        #Object([
            ("width", #Number(#Int(video.width))),
            ("height", #Number(#Int(video.height))),
            ("thumbnail_data", #String(video.thumbnailData)),
            (
                "caption",
                serializeNullable<Text>(video.caption, serializeText),
            ),
            ("mime_type", #String(video.mimeType)),
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

    private func serializeAudioContent(audio : SdkTypes.AudioContent) : Json.JSON {
        #Object([
            (
                "caption",
                serializeNullable<Text>(audio.caption, serializeText),
            ),
            ("mime_type", #String(audio.mimeType)),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(audio.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeFileContent(file : SdkTypes.FileContent) : Json.JSON {
        #Object([
            ("name", #String(file.name)),
            (
                "caption",
                serializeNullable<Text>(file.caption, serializeText),
            ),
            ("mime_type", #String(file.mimeType)),
            ("file_size", #Number(#Int(file.fileSize))),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(file.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializePollContent(poll : SdkTypes.PollContent) : Json.JSON {
        #Object([
            ("config", serializePollConfig(poll.config)),
        ]);
    };

    private func serializePollConfig(pollConfig : SdkTypes.PollConfig) : Json.JSON {
        #Object([
            ("text", serializeNullable<Text>(pollConfig.text, serializeText)),
            ("options", serializeArrayOfValues(pollConfig.options, serializeText)),
            (
                "end_date",
                serializeNullable<Nat>(pollConfig.endDate, serializeInt),
            ),
            ("anonymous", #Bool(pollConfig.anonymous)),
            ("show_votes_before_end_date", #Bool(pollConfig.showVotesBeforeEndDate)),
            ("allow_multiple_votes_per_user", #Bool(pollConfig.allowMultipleVotesPerUser)),
            ("allow_user_to_change_vote", #Bool(pollConfig.allowUserToChangeVote)),
        ]);
    };

    private func serializeGiphyContent(giphy : SdkTypes.GiphyContent) : Json.JSON {
        #Object([
            ("caption", serializeNullable<Text>(giphy.caption, serializeText)),
            ("title", #String(giphy.title)),
            ("desktop", serializeGiphyImageVariant(giphy.desktop)),
            ("mobile", serializeGiphyImageVariant(giphy.mobile)),
        ]);
    };

    private func serializeGiphyImageVariant(giphyImageVariant : SdkTypes.GiphyImageVariant) : Json.JSON {
        #Object([
            ("width", #Number(#Int(giphyImageVariant.width))),
            ("height", #Number(#Int(giphyImageVariant.height))),
            ("url", #String(giphyImageVariant.url)),
            ("mime_type", #String(giphyImageVariant.mimeType)),
        ]);
    };

    private func serializeText(option : Text) : Json.JSON = #String(option);

    private func serializeInt(int : Int) : Json.JSON = #Number(#Int(int));

    private func serializeArrayOfValues<T>(values : [T], serializer : T -> Json.JSON) : Json.JSON {
        #Array(values.vals() |> Iter.map(_, serializer) |> Iter.toArray(_));
    };

    private func serializeBlobReference(blobReference : SdkTypes.BlobReference) : Json.JSON {
        #Object([
            ("canister_id", #String(Principal.toText(blobReference.canister))),
            (
                "blob_id",
                #Number(#Int(blobReference.blobId)),
            ),
        ]);
    };

    private func serializeNullable<T>(value : ?T, serializer : T -> Json.JSON) : Json.JSON {
        switch (value) {
            case (null) #Null;
            case (?v) serializer(v);
        };
    };

    public func serializeBadRequest(badRequest : SdkTypes.BadRequestResult) : Json.JSON {
        switch (badRequest) {
            case (#accessTokenNotFound) #String("AccessTokenNotFound");
            case (#accessTokenInvalid) #String("AccessTokenInvalid");
            case (#accessTokenExpired) #String("AccessTokenExpired");
            case (#commandNotFound) #String("CommandNotFound");
            case (#argsInvalid) #String("ArgsInvalid");
        };
    };

    public func serializeInternalError(error : SdkTypes.InternalErrorResult) : Json.JSON {
        switch (error) {
            case (#invalid(invalid)) serializeVariantWithValue("Invalid", #String(invalid));
            case (#canisterError(canisterError)) serializeVariantWithValue("CanisterError", serializeCanisterError(canisterError));
            case (#c2cError((code, message))) serializeVariantWithValue("C2CError", #Array([#Number(#Int(code)), #String(message)]));
        };
    };

    private func serializeCanisterError(canisterError : SdkTypes.CanisterError) : Json.JSON {
        switch (canisterError) {
            case (#notAuthorized) #String("NotAuthorized");
            case (#frozen) #String("Frozen");
            case (#other(other)) serializeVariantWithValue("Other", #String(other));
        };
    };

    private func serializeVariantWithValue(variant : Text, value : Json.JSON) : Json.JSON {
        #Object([(variant, value)]);
    };

    public func deserializeCommand(body : Blob) : ?SdkTypes.BotActionByCommand {
        let ?jwt = Text.decodeUtf8(body) else return null;

        let publicKeyPem = "TODO";
        let botActionJson = switch (verify(jwt, publicKeyPem)) {
            case (#ok(claims)) claims;
            case (#err(_)) return null;
        };
        deserializeCommandClaims(botActionJson);
    };

    private func deserializeCommandClaims(dataJson : Json.JSON) : ?SdkTypes.BotActionByCommand {
        let ?#Object(scopeKeys) = Json.get(dataJson, "scope") else return null;
        let scope : SdkTypes.BotActionScope = switch (scopeKeys[0]) {
            case (("Chat", chatValue)) {
                let ?chat = deserializeBotActionChatDetails(chatValue) else return null;
                #chat(chat);
            };
            case (("Community", communityValue)) {
                let ?community = deserializeBotActionCommunityDetails(communityValue) else return null;
                #community(community);
            };
            case (_) return null;
        };

        let ?botApiGateway = getAsPrincipal(dataJson, "bot_api_gateway") else return null;
        let ?bot = getAsPrincipal(dataJson, "bot") else return null;

        let ?#Object(grantedPermissionsKeys) = Json.get(dataJson, "granted_permissions") else return null;
        let grantedPermissions : SdkTypes.BotPermissions = switch (grantedPermissionsKeys[0]) {
            case (("Community", communityValue)) {
                let ?communityPermissions = deserializeArrayOfValues(communityValue, deserializeCommunityPermission) else return null;
                #community(communityPermissions);
            };
            case (("Chat", chatValue)) {
                let ?groupPermissions = deserializeArrayOfValues(chatValue, deserializeGroupPermission) else return null;
                #chat(groupPermissions);
            };
            case (("Message", messageValue)) {
                let ?messagePermissions = deserializeArrayOfValues(messageValue, deserializeMessagePermission) else return null;
                #message(messagePermissions);
            };
            case (_) return null;
        };
        let ?#String(commandName) = Json.get(dataJson, "command.name") else return null;
        let ?commandArgsJson = Json.get(dataJson, "command.args") else return null;
        let ?commandArgs = deserializeArrayOfValues(commandArgsJson, deserializeCommandArg) else return null;
        let ?initiator = getAsPrincipal(dataJson, "command.initiator") else return null;
        let command : SdkTypes.Command = {
            name = commandName;
            args = commandArgs;
            initiator = initiator;
        };

        ?{

            botApiGateway = botApiGateway;
            bot = bot;
            scope = scope;
            grantedPermissions = grantedPermissions;
            command = command;
        };
    };

    private func deserializeArrayOfValues<T>(json : Json.JSON, deserialize : Json.JSON -> ?T) : ?[T] {
        let #Array(arrayJson) = json else return null;
        let buffer = Buffer.Buffer<T>(arrayJson.size());

        for (val in arrayJson.vals()) {
            let ?deserializedValue = deserialize(val) else return null;
            buffer.add(deserializedValue);
        };
        ?Buffer.toArray(buffer);
    };

    private func deserializeCommandArg(json : Json.JSON) : ?SdkTypes.CommandArg {
        let ?#String(name) = Json.get(json, "name") else return null;
        let ?#Object(valueJsonKeys) = Json.get(json, "value") else return null;
        let value : SdkTypes.CommandArgValue = switch (valueJsonKeys[0]) {
            case (("String", stringValue)) {
                let ?string = getAsText(stringValue, "") else return null;
                #string(string);
            };
            case (_) return null;
        };
        ?{
            name = name;
            value = value;
        };
    };

    private func deserializeMessagePermission(json : Json.JSON) : ?SdkTypes.MessagePermission {
        let #String(permissionString) = json else return null;

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
            case (_) return null;
        };
        ?permission;
    };

    private func deserializeGroupPermission(json : Json.JSON) : ?SdkTypes.GroupPermission {
        let #String(permissionString) = json else return null;

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
            case (_) return null;
        };
        ?permission;
    };

    private func deserializeCommunityPermission(json : Json.JSON) : ?SdkTypes.CommunityPermission {
        let #String(permissionString) = json else return null;

        let permission : SdkTypes.CommunityPermission = switch (permissionString) {
            case ("ChangeRoles") #changeRoles;
            case ("UpdateDetails") #updateDetails;
            case ("InviteUsers") #inviteUsers;
            case ("RemoveMembers") #removeMembers;
            case ("CreatePublicChannel") #createPublicChannel;
            case ("CreatePrivateChannel") #createPrivateChannel;
            case ("ManageUserGroups") #manageUserGroups;
            case (_) return null;
        };
        ?permission;
    };

    private func deserializeBotActionChatDetails(dataJson : Json.JSON) : ?SdkTypes.BotActionChatDetails {
        let ?#Object(chatKeys) = Json.get(dataJson, "chat") else return null;
        let chat : SdkTypes.Chat = switch (chatKeys[0]) {
            case (("Direct", directValue)) {
                let ?directPrincipal = getAsPrincipal(directValue, "") else return null;
                #direct(directPrincipal);
            };
            case (("Group", groupValue)) {
                let ?groupPrincipal = getAsPrincipal(groupValue, "") else return null;
                #group(groupPrincipal);
            };
            case (("Channel", channelValue)) {
                let ?channelPrincipal = getAsPrincipal(channelValue, "[0]") else return null;
                let ?channelId = getAsNat(channelValue, "[1]") else return null;
                #channel((channelPrincipal, channelId));
            };
            case (_) return null;
        };

        let threadRootMessageIndex = getAsNat(dataJson, "thread_root_message_index");

        let ?messageId = getAsText(dataJson, "message_id") else return null;

        ?{
            chat = chat;
            threadRootMessageIndex = threadRootMessageIndex;
            messageId = messageId;
        };
    };
    private func deserializeBotActionCommunityDetails(dataJson : Json.JSON) : ?SdkTypes.BotActionCommunityDetails {
        let ?communityId = getAsPrincipal(dataJson, "community_id") else return null;

        ?{
            communityId = communityId;
        };
    };

    private func verify<T>(jwt : Text, _ : Text) : Result.Result<Json.JSON, Text> {
        // Split JWT into parts
        let parts = Text.split(jwt, #char('.')) |> Iter.toArray(_);

        if (parts.size() != 3) {
            return #err("Invalid JWT");
        };

        // TODO
        // let headerJson = parts[0];
        let claimsJson = parts[1];
        // let signatureStr = parts[2];

        // // Decode base64url signature to bytes
        let base64UrlEngine = Base64.Base64(#v(Base64.V2), ?true);
        // let signatureBytes = base64UrlEngine.decode(signatureStr); // TODO handle error

        // // Create message to verify (header + "." + claims)
        // let message = Text.concat(headerJson, Text.concat(".", claimsJson));
        // let messageBytes = Blob.toArray(Text.encodeUtf8(message));

        // // Parse PEM public key and verify signature
        // let #ok = await* ECDSA.verify({
        //     publicKey = publicKeyPem;
        //     message = messageBytes;
        //     signature = signatureBytes;
        //     algorithm = #P256;
        // }) else return return #err("Signature verification failed");

        // Decode and parse claims
        let claimsBytes = base64UrlEngine.decode(claimsJson); // TODO handle error
        let ?claimsText = Text.decodeUtf8(Blob.fromArray(claimsBytes)) else return #err("Unable to parse claims");
        switch (Json.parse(claimsText)) {
            case (#err(e)) #err("Invalid claims JSON: " # debug_show (e));
            case (#ok(claims)) {
                let ?expJson = Json.get(claims, "exp") else return #err("Missing 'exp' field in claims");
                let #Number(#Int(expInt)) = expJson else return #err("Invalid 'exp' field in claims, must be an integer");
                // TODO is nanoseconds? or millis?
                if (expInt < Time.now()) {
                    return #err("JWT has expired");
                };

                let ?claimTypeJson = Json.get(claims, "claimType") else return #err("Missing 'claimType' field in claims");
                let #String(_) = claimTypeJson else return #err("Invalid 'claimType' field in claims, must be a string");

                // TODO claim type?

                let ?dataJson = Json.get(claims, "data") else return #err("Missing 'data' field in claims");

                #ok(dataJson);
            };
        };
    };

    private func getAsNat(json : Json.JSON, path : Json.Path) : ?Nat {
        let ?value = Json.get(json, path) else return null;
        let #Number(#Int(intValue)) = value else return null;
        if (intValue < 0) {
            // Must be a positive integer
            return null;
        };
        ?Int.abs(intValue);
    };

    private func getAsText(json : Json.JSON, path : Json.Path) : ?Text {
        let ?value = Json.get(json, path) else return null;
        let #String(text) = value else return null;
        ?text;
    };

    private func getAsPrincipal(json : Json.JSON, path : Json.Path) : ?Principal {
        let ?principalStr = getAsText(json, path) else return null;
        ?Principal.fromText(principalStr);
    };
};
