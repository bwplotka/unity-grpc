package main

import (
	"fmt"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	pb "github.com/Bplotka/unity-grpc/example/go-server/model/example"
)

const (
	// Change that if you want any other address.
	listenAddr = "127.0.0.1:9991"
)

type MultiGreeterService struct{}

func (m *MultiGreeterService) SayHello(req *pb.HelloRequest, stream pb.MultiGreeter_SayHelloServer) error {
	log.Println("Some client wants a greeting!")
	for i := uint32(0); i < req.NumGreetings; i++ {
		// Add some fake latency.
		time.Sleep(1 * time.Second)
		if err := stream.Send(&pb.HelloReply{
			Message: fmt.Sprintf("Hello %s", req.Name),
		}); err != nil {
			return err
		}
		log.Println("Sent greeting")
	}
	log.Println("No more greetings")
	return nil
}

func main() {
	lis, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	grpcServer := grpc.NewServer()
	pb.RegisterMultiGreeterServer(grpcServer, &MultiGreeterService{})

	log.Printf("Starting listening on %s", listenAddr)
	// We don't care about TLS for this example.
	grpcServer.Serve(lis)
}
