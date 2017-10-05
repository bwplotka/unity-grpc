# unity-grpc
gRPC lib ported to support .Net 3.5 (unity 4+) with Tutorial.

If you are interested in gRPC usage in your Unity and you don't want to wait for Unity C# .Net 4.5 support... this is a tutorial for you!
 
All credits for providing gRPC library goes to https://github.com/neuecc 

`lib/gRPC` code was copied without single change from [here](https://github.com/neuecc/MagicOnion/tree/3e04e797a00ba49807654c8c13808875c5fd92c0/src/MagicOnion.Client.Unity/Assets/Scripts/gRPC)

The idea of this short tutorial came in response to https://github.com/neuecc/MagicOnion/issues/18

## Tutorial

### Client (Unity with C# .Net 3.5)

* Create new project
* Copy `lib/gRPC` directory to your Assets (you can just drag & drop it in your unity) 

From now on, we need to solve all dependency issues to support gRPC lib and protobufs.

* Install UniRx from AssetStore (async lib used by this gRPC lib)
  * Window > AssetStore
  * Find UniRx - Reactive Extension for Unity > Login > Import
  
At that point you should be able to build all in Visual Studio (or any IDE else you are using).
 
Let's now run through some example of gRPC client <-> server communication with the client side in Unity.
I will use standard example from grpc repo with server streaming: https://github.com/grpc/grpc/blob/master/examples/protos/hellostreamingworld.proto

We cannot use gRPC generated code for C#, because it uses .Net 4.5+ code, but we can
stil generate protobuf messages (including serialization) that will be .Net 3.5 compatible C# data structures.

The cool part is, that you can use exactly the same proto file with service definition. Protobuf will 
just ignore this, so you can generate gRPC + protobuf messages for server (in my example it will be Golang), and
C# protobuf messages for client. 

The only manual part is to use gRPC lib's classes provided in `lib/gRPC` to call known ServiceName and Method you prepared. This is normally done by gRPC generated code from proto itself, but needed to recreate that manually [here](./examples/csharp-client/GreeterClient.cs). We could write plugin to generate this, but having .Net 4.5 C# support in Unity "soon-ish", not sure if it's worth it.

* Go to example directory.
* Run `bash ./example/protogen_csharp.sh` (I am using windows migw32) to generate protobuf messages for our example.

This scripts is using protoc-3.0.0, which is provided in this repo [here](.\bin\protoc-3.0.0-win32). This is standard protoc downloaded from upstream.
You can use `protogen_csharp` script to generate your own stuff. However, generated protobufs are already commited into this repo
for convenience.

* Copy example/csharp-client to Unity Assets. (you can drag & drop it). This contains:
  * generated proto messages
  * manually written client
  * Unity TestGrpcBehaviour that tries to run the service targeting 127.0.0.1:9991

Now you should immediately see errors like:
```
Assets/csharp-client/Model/Greeter.cs(6,12): error CS0400: The type or namespace name `Google' could not be found in the global namespace (are you missing an assembly reference?)
```

This is tricky part, because we need to get protobuf library that will fit with .Net 3.5

I used this great fork https://github.com/emikra/protobuf3-cs.
Nuget install command from README.md totally did not work for me (visual 2013), so I ended up
building the dll myself (using visual 2017)

* Copy provided dll from protobuf-net35/protobuf3.dll into your unity Assets

There is a risk it will not work you (not sure if I built for x86 or x64, so you might want to rebuild 
it from source if needed.

From now you should be able to rebuild the Unity code. 

However when you use Unity Free version. When you run the code it will fail with (more fun!):
```
DllNotFoundException: grpc_csharp_ext
Grpc.Core.Internal.NativeLogRedirector.Redirect (Grpc.Core.Internal.NativeMethods native) (at Assets/gRPC/Core/Internal/NativeLogRedirector.cs:63)
Grpc.Core.Internal.NativeExtension..ctor () (at Assets/gRPC/Core/Internal/NativeExtension.cs:59)
Grpc.Core.Internal.NativeExtension.Get () (at Assets/gRPC/Core/Internal/NativeExtension.cs:77)
Grpc.Core.Internal.NativeMethods.Get () (at Assets/gRPC/Core/Internal/NativeMethods.cs:269)
Grpc.Core.GrpcEnvironment.GrpcNativeInit () (at Assets/gRPC/Core/GrpcEnvironment.cs:314)
Grpc.Core.GrpcEnvironment..ctor () (at Assets/gRPC/Core/GrpcEnvironment.cs:250)
Grpc.Core.GrpcEnvironment.AddRef () (at Assets/gRPC/Core/GrpcEnvironment.cs:117)
Grpc.Core.Channel..ctor (System.String target, Grpc.Core.ChannelCredentials credentials, IEnumerable`1 options) (at Assets/gRPC/Core/Channel.cs:87)
Grpc.Core.Channel..ctor (System.String host, Int32 port, Grpc.Core.ChannelCredentials credentials, IEnumerable`1 options)
Grpc.Core.Channel..ctor (System.String host, Int32 port, Grpc.Core.ChannelCredentials credentials)
Example.Client..ctor (System.String host, Int32 port) (at Assets/csharp-client/GreeterClient.cs:52)
TestGRPCBehaviour.Start () (at Assets/csharp-client/TestGRPCBehaviour.cs:12)
```

This is because of some native API calls used by gRPC core. (https://github.com/grpc/grpc/issues/905)

The problem with Free Unity is that it does not support unmanaged dlls packed into per platform directories 
as we have in `lib/gRPC/Native/(...)`. (called "plugins" support)

What we can do, we can copy the dll you need and place it in Unity root (above Assets!).
You will also need to copy this dll with you binary everywhere you want to export it on release.
You can find more details here: http://ericeastwood.com/blog/17/unity-and-dlls-c-managed-and-c-unmanaged

Once you provide `grpc_csharp_ext.dll` there is only last step missing.
Last step for client-side is to pin behaviour to any game object in your scene

* Create new GameObject > AddComponent > Put TestGRPCBehaviour.cs as Script

You can run Unity now, but it will fail... Since there is no server running around (:

```
RpcException: Status(StatusCode=Unavailable, Detail="Connect Failed")
UniRx.Stubs.<Throw>m__6B (System.Exception ex) (at Assets/Plugins/UniRx/Scripts/Observer.cs:495)
UniRx.Observable+<ToAwaitableEnumerator>c__Iterator10`1[System.Boolean].MoveNext () (at Assets/Plugins/UniRx/Scripts/UnityEngineBridge/Observable.Unity.cs:939)
```
### Server (Go)

Prepate go enviroment (golang installed, GOPATH exported)

* Follow https://grpc.io/docs/quickstart/go.html
* `go get github.com/google/protobuf/...`
* Run `bash ./example/protogen_go.sh`
* Start server using `go run example/go-server/server.go`

Ii will listen on 127.0.0.1:9991

* Now let's start our unity again.

You should be able to see logs on both Go server and Unity with gRPC communication!

I hope this tutorial will help to create your own gRPC client (: 

