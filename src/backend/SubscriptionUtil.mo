import Text "mo:base/Text";
import Subscriber "mo:icrc72-subscriber-mo";
import ClassPlus "mo:class-plus";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Vector "mo:vector";
import Debug "mo:base/Debug";
import TimerTool "mo:timer-tool";
import Timer "mo:base/Timer";

module {
    public func create<system>(
        canisterId : Principal,
        orchestratorPrincipal : Principal,
        owner : Principal,
        timerStableData : TimerTool.State,
        onTimerStableDataChange : (TimerTool.State) -> (),
        subscriberStableData : Subscriber.State,
        onSubscriberStableDataChange : (Subscriber.State) -> (),
    ) : () -> Subscriber.Subscriber {

        let records = Vector.new<([(Text, Subscriber.Value)], [(Text, Subscriber.Value)])>();

        func addRecord(trx : [(Text, Subscriber.Value)], trxTop : ?[(Text, Subscriber.Value)]) : Nat {
            Vector.add(
                records,
                (
                    trx,
                    switch (trxTop) {
                        case (?val) val;
                        case (null) [];
                    },
                ),
            );
            return Vector.size(records);
        };

        let initManager = ClassPlus.ClassPlusInitializationManager(owner, canisterId, true);
        let tt = TimerTool.Init<system>({
            manager = initManager;
            initialState = timerStableData;
            args = null;
            pullEnvironment = ?(
                func() : TimerTool.Environment {
                    {
                        advanced = null;
                        reportExecution = null;
                        reportError = null;
                        syncUnsafe = null;
                        reportBatch = null;
                    };
                }
            );

            onInitialize = ?(
                func(newClass : TimerTool.TimerTool) : async* () {
                    Debug.print("Initializing TimerTool");
                    newClass.initialize<system>();
                }
            );
            onStorageChange = onTimerStableDataChange;
        });

        Subscriber.Init<system>({
            manager = initManager;
            initialState = subscriberStableData;
            args = null;
            pullEnvironment = ?(
                func() : Subscriber.Environment {
                    {
                        advanced = null;
                        var addRecord = ?addRecord;
                        var icrc72OrchestratorCanister = orchestratorPrincipal;
                        tt = tt();
                        //5_000_000 call fee
                        //260_000 x net call feee
                        //1_000 x net byte fee (per byte)
                        //127_000 per gbit per second.
                        var handleEventOrder = null;
                        var handleNotificationPrice = ?Subscriber.ReflectWithMaxStrategy("com.panindustrial.icaibus.message.cycles", 10_000_000_000);
                        var onSubscriptionReady = null;
                        var handleNotificationError = null;
                    };
                }
            );
            onInitialize = ?(
                func(newClass : Subscriber.Subscriber) : async* () {
                    Debug.print("Initializing Subscriber");
                    ignore Timer.setTimer<system>(#nanoseconds(0), newClass.initializeSubscriptions);
                    //do any work here necessary for initialization
                }
            );
            onStorageChange = onSubscriberStableDataChange;
        });
    };
};
