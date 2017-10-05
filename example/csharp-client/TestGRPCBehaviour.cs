using System;
using Grpc.Core;
using UnityEngine;
using System.Collections;
using UniRx;

public class TestGRPCBehaviour : MonoBehaviour {

    private int replyCount;
	// Use this for initialization
	void Start () {
        var client = new Example.Client("127.0.0.1", 9991);

        Debug.Log("Stating calling gRPC service to greet me 10 times");

        // You can setup some timeout here...
        var ctx = new GrpcCancellationTokenSource();
        AsyncServerStreamingCall<Example.HelloReply> call = client.SayHello(ctx, new Example.HelloRequest
        {
            Name = "CuriousUser!11one!one",
            NumGreetings = 10
        });
        // Schedule response parsing in async.
        call.ResponseStream.MoveNext().StartAsCoroutine<bool>(this.onNextFn(call));
	}

    Action<bool> onNextFn(AsyncServerStreamingCall<Example.HelloReply> call)
    {
        return ok =>
        {
            if (ok)
            {
                replyCount++;
                Example.HelloReply helloReply = call.ResponseStream.Current;
                Debug.Log("Got " + replyCount.ToString() + " greeting, I think: " + helloReply.Message);
                call.ResponseStream.MoveNext().StartAsCoroutine<bool>(this.onNextFn(call));
            }
            else
            {
                Debug.Log("End of stream or failure. Status: " + call.GetStatus() + ". Retrying!");
                call.Dispose();
            }
        };
    }
}
