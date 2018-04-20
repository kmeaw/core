// Code generated by protoc-gen-go. DO NOT EDIT.
// source: marketplace.proto

package sonm

import proto "github.com/golang/protobuf/proto"
import fmt "fmt"
import math "math"

import (
	context "golang.org/x/net/context"
	grpc "google.golang.org/grpc"
)

// grpccmd imports
import (
	"io"

	"github.com/spf13/cobra"
	"github.com/sshaman1101/grpccmd"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

type MarketOrderType int32

const (
	MarketOrderType_MARKET_ANY MarketOrderType = 0
	MarketOrderType_MARKET_BID MarketOrderType = 1
	MarketOrderType_MARKET_ASK MarketOrderType = 2
)

var MarketOrderType_name = map[int32]string{
	0: "MARKET_ANY",
	1: "MARKET_BID",
	2: "MARKET_ASK",
}
var MarketOrderType_value = map[string]int32{
	"MARKET_ANY": 0,
	"MARKET_BID": 1,
	"MARKET_ASK": 2,
}

func (x MarketOrderType) String() string {
	return proto.EnumName(MarketOrderType_name, int32(x))
}
func (MarketOrderType) EnumDescriptor() ([]byte, []int) { return fileDescriptor10, []int{0} }

type MarketOrderStatus int32

const (
	MarketOrderStatus_MARKET_ORDER_INACTIVE MarketOrderStatus = 0
	MarketOrderStatus_MARKET_ORDER_ACTIVE   MarketOrderStatus = 1
)

var MarketOrderStatus_name = map[int32]string{
	0: "MARKET_ORDER_INACTIVE",
	1: "MARKET_ORDER_ACTIVE",
}
var MarketOrderStatus_value = map[string]int32{
	"MARKET_ORDER_INACTIVE": 0,
	"MARKET_ORDER_ACTIVE":   1,
}

func (x MarketOrderStatus) String() string {
	return proto.EnumName(MarketOrderStatus_name, int32(x))
}
func (MarketOrderStatus) EnumDescriptor() ([]byte, []int) { return fileDescriptor10, []int{1} }

type MarketIdentityLevel int32

const (
	MarketIdentityLevel_MARKET_ANONIMOUS    MarketIdentityLevel = 0
	MarketIdentityLevel_MARKET_PSEUDONYMOUS MarketIdentityLevel = 1
	MarketIdentityLevel_MARKET_IDENTIFIED   MarketIdentityLevel = 2
)

var MarketIdentityLevel_name = map[int32]string{
	0: "MARKET_ANONIMOUS",
	1: "MARKET_PSEUDONYMOUS",
	2: "MARKET_IDENTIFIED",
}
var MarketIdentityLevel_value = map[string]int32{
	"MARKET_ANONIMOUS":    0,
	"MARKET_PSEUDONYMOUS": 1,
	"MARKET_IDENTIFIED":   2,
}

func (x MarketIdentityLevel) String() string {
	return proto.EnumName(MarketIdentityLevel_name, int32(x))
}
func (MarketIdentityLevel) EnumDescriptor() ([]byte, []int) { return fileDescriptor10, []int{2} }

type MarketDealStatus int32

const (
	MarketDealStatus_MARKET_STATUS_UNKNOWN  MarketDealStatus = 0
	MarketDealStatus_MARKET_STATUS_ACCEPTED MarketDealStatus = 1
	MarketDealStatus_MARKET_STATUS_CLOSED   MarketDealStatus = 2
)

var MarketDealStatus_name = map[int32]string{
	0: "MARKET_STATUS_UNKNOWN",
	1: "MARKET_STATUS_ACCEPTED",
	2: "MARKET_STATUS_CLOSED",
}
var MarketDealStatus_value = map[string]int32{
	"MARKET_STATUS_UNKNOWN":  0,
	"MARKET_STATUS_ACCEPTED": 1,
	"MARKET_STATUS_CLOSED":   2,
}

func (x MarketDealStatus) String() string {
	return proto.EnumName(MarketDealStatus_name, int32(x))
}
func (MarketDealStatus) EnumDescriptor() ([]byte, []int) { return fileDescriptor10, []int{3} }

type MarketChangeRequestStatus int32

const (
	MarketChangeRequestStatus_REQUEST_UNKNOWN  MarketChangeRequestStatus = 0
	MarketChangeRequestStatus_REQUEST_CREATED  MarketChangeRequestStatus = 1
	MarketChangeRequestStatus_REQUEST_CANCELED MarketChangeRequestStatus = 2
	MarketChangeRequestStatus_REQUEST_REJECTED MarketChangeRequestStatus = 3
	MarketChangeRequestStatus_REQUEST_ACCEPTED MarketChangeRequestStatus = 4
)

var MarketChangeRequestStatus_name = map[int32]string{
	0: "REQUEST_UNKNOWN",
	1: "REQUEST_CREATED",
	2: "REQUEST_CANCELED",
	3: "REQUEST_REJECTED",
	4: "REQUEST_ACCEPTED",
}
var MarketChangeRequestStatus_value = map[string]int32{
	"REQUEST_UNKNOWN":  0,
	"REQUEST_CREATED":  1,
	"REQUEST_CANCELED": 2,
	"REQUEST_REJECTED": 3,
	"REQUEST_ACCEPTED": 4,
}

func (x MarketChangeRequestStatus) String() string {
	return proto.EnumName(MarketChangeRequestStatus_name, int32(x))
}
func (MarketChangeRequestStatus) EnumDescriptor() ([]byte, []int) { return fileDescriptor10, []int{4} }

type GetOrdersRequest struct {
	Type         MarketOrderType `protobuf:"varint,1,opt,name=type,enum=sonm.MarketOrderType" json:"type,omitempty"`
	Price        *BigInt         `protobuf:"bytes,2,opt,name=Price" json:"Price,omitempty"`
	Counterparty *EthAddress     `protobuf:"bytes,3,opt,name=Counterparty" json:"Counterparty,omitempty"`
	Count        uint64          `protobuf:"varint,4,opt,name=count" json:"count,omitempty"`
}

func (m *GetOrdersRequest) Reset()                    { *m = GetOrdersRequest{} }
func (m *GetOrdersRequest) String() string            { return proto.CompactTextString(m) }
func (*GetOrdersRequest) ProtoMessage()               {}
func (*GetOrdersRequest) Descriptor() ([]byte, []int) { return fileDescriptor10, []int{0} }

func (m *GetOrdersRequest) GetType() MarketOrderType {
	if m != nil {
		return m.Type
	}
	return MarketOrderType_MARKET_ANY
}

func (m *GetOrdersRequest) GetPrice() *BigInt {
	if m != nil {
		return m.Price
	}
	return nil
}

func (m *GetOrdersRequest) GetCounterparty() *EthAddress {
	if m != nil {
		return m.Counterparty
	}
	return nil
}

func (m *GetOrdersRequest) GetCount() uint64 {
	if m != nil {
		return m.Count
	}
	return 0
}

type GetOrdersReply struct {
	Orders []*MarketOrder `protobuf:"bytes,1,rep,name=orders" json:"orders,omitempty"`
}

func (m *GetOrdersReply) Reset()                    { *m = GetOrdersReply{} }
func (m *GetOrdersReply) String() string            { return proto.CompactTextString(m) }
func (*GetOrdersReply) ProtoMessage()               {}
func (*GetOrdersReply) Descriptor() ([]byte, []int) { return fileDescriptor10, []int{1} }

func (m *GetOrdersReply) GetOrders() []*MarketOrder {
	if m != nil {
		return m.Orders
	}
	return nil
}

type MarketDeal struct {
	Id             string           `protobuf:"bytes,1,opt,name=id" json:"id,omitempty"`
	Benchmarks     []uint64         `protobuf:"varint,2,rep,packed,name=benchmarks" json:"benchmarks,omitempty"`
	SupplierID     string           `protobuf:"bytes,3,opt,name=supplierID" json:"supplierID,omitempty"`
	ConsumerID     string           `protobuf:"bytes,4,opt,name=consumerID" json:"consumerID,omitempty"`
	MasterID       string           `protobuf:"bytes,5,opt,name=masterID" json:"masterID,omitempty"`
	AskID          string           `protobuf:"bytes,6,opt,name=askID" json:"askID,omitempty"`
	BidID          string           `protobuf:"bytes,7,opt,name=bidID" json:"bidID,omitempty"`
	Duration       uint64           `protobuf:"varint,8,opt,name=duration" json:"duration,omitempty"`
	Price          *BigInt          `protobuf:"bytes,9,opt,name=price" json:"price,omitempty"`
	StartTime      *Timestamp       `protobuf:"bytes,10,opt,name=startTime" json:"startTime,omitempty"`
	EndTime        *Timestamp       `protobuf:"bytes,11,opt,name=endTime" json:"endTime,omitempty"`
	Status         MarketDealStatus `protobuf:"varint,12,opt,name=status,enum=sonm.MarketDealStatus" json:"status,omitempty"`
	BlockedBalance *BigInt          `protobuf:"bytes,13,opt,name=blockedBalance" json:"blockedBalance,omitempty"`
	TotalPayout    *BigInt          `protobuf:"bytes,14,opt,name=totalPayout" json:"totalPayout,omitempty"`
	LastBillTS     *Timestamp       `protobuf:"bytes,15,opt,name=lastBillTS" json:"lastBillTS,omitempty"`
}

func (m *MarketDeal) Reset()                    { *m = MarketDeal{} }
func (m *MarketDeal) String() string            { return proto.CompactTextString(m) }
func (*MarketDeal) ProtoMessage()               {}
func (*MarketDeal) Descriptor() ([]byte, []int) { return fileDescriptor10, []int{2} }

func (m *MarketDeal) GetId() string {
	if m != nil {
		return m.Id
	}
	return ""
}

func (m *MarketDeal) GetBenchmarks() []uint64 {
	if m != nil {
		return m.Benchmarks
	}
	return nil
}

func (m *MarketDeal) GetSupplierID() string {
	if m != nil {
		return m.SupplierID
	}
	return ""
}

func (m *MarketDeal) GetConsumerID() string {
	if m != nil {
		return m.ConsumerID
	}
	return ""
}

func (m *MarketDeal) GetMasterID() string {
	if m != nil {
		return m.MasterID
	}
	return ""
}

func (m *MarketDeal) GetAskID() string {
	if m != nil {
		return m.AskID
	}
	return ""
}

func (m *MarketDeal) GetBidID() string {
	if m != nil {
		return m.BidID
	}
	return ""
}

func (m *MarketDeal) GetDuration() uint64 {
	if m != nil {
		return m.Duration
	}
	return 0
}

func (m *MarketDeal) GetPrice() *BigInt {
	if m != nil {
		return m.Price
	}
	return nil
}

func (m *MarketDeal) GetStartTime() *Timestamp {
	if m != nil {
		return m.StartTime
	}
	return nil
}

func (m *MarketDeal) GetEndTime() *Timestamp {
	if m != nil {
		return m.EndTime
	}
	return nil
}

func (m *MarketDeal) GetStatus() MarketDealStatus {
	if m != nil {
		return m.Status
	}
	return MarketDealStatus_MARKET_STATUS_UNKNOWN
}

func (m *MarketDeal) GetBlockedBalance() *BigInt {
	if m != nil {
		return m.BlockedBalance
	}
	return nil
}

func (m *MarketDeal) GetTotalPayout() *BigInt {
	if m != nil {
		return m.TotalPayout
	}
	return nil
}

func (m *MarketDeal) GetLastBillTS() *Timestamp {
	if m != nil {
		return m.LastBillTS
	}
	return nil
}

type MarketOrder struct {
	Id             string              `protobuf:"bytes,1,opt,name=id" json:"id,omitempty"`
	DealID         string              `protobuf:"bytes,2,opt,name=dealID" json:"dealID,omitempty"`
	OrderType      MarketOrderType     `protobuf:"varint,3,opt,name=orderType,enum=sonm.MarketOrderType" json:"orderType,omitempty"`
	OrderStatus    MarketOrderStatus   `protobuf:"varint,4,opt,name=orderStatus,enum=sonm.MarketOrderStatus" json:"orderStatus,omitempty"`
	AuthorID       string              `protobuf:"bytes,5,opt,name=authorID" json:"authorID,omitempty"`
	CounterpartyID string              `protobuf:"bytes,6,opt,name=counterpartyID" json:"counterpartyID,omitempty"`
	Duration       uint64              `protobuf:"varint,7,opt,name=duration" json:"duration,omitempty"`
	Price          *BigInt             `protobuf:"bytes,8,opt,name=price" json:"price,omitempty"`
	Netflags       uint64              `protobuf:"varint,9,opt,name=netflags" json:"netflags,omitempty"`
	IdentityLevel  MarketIdentityLevel `protobuf:"varint,10,opt,name=identityLevel,enum=sonm.MarketIdentityLevel" json:"identityLevel,omitempty"`
	Blacklist      string              `protobuf:"bytes,11,opt,name=blacklist" json:"blacklist,omitempty"`
	Tag            []byte              `protobuf:"bytes,12,opt,name=tag,proto3" json:"tag,omitempty"`
	Benchmarks     []uint64            `protobuf:"varint,13,rep,packed,name=benchmarks" json:"benchmarks,omitempty"`
	FrozenSum      *BigInt             `protobuf:"bytes,14,opt,name=frozenSum" json:"frozenSum,omitempty"`
}

func (m *MarketOrder) Reset()                    { *m = MarketOrder{} }
func (m *MarketOrder) String() string            { return proto.CompactTextString(m) }
func (*MarketOrder) ProtoMessage()               {}
func (*MarketOrder) Descriptor() ([]byte, []int) { return fileDescriptor10, []int{3} }

func (m *MarketOrder) GetId() string {
	if m != nil {
		return m.Id
	}
	return ""
}

func (m *MarketOrder) GetDealID() string {
	if m != nil {
		return m.DealID
	}
	return ""
}

func (m *MarketOrder) GetOrderType() MarketOrderType {
	if m != nil {
		return m.OrderType
	}
	return MarketOrderType_MARKET_ANY
}

func (m *MarketOrder) GetOrderStatus() MarketOrderStatus {
	if m != nil {
		return m.OrderStatus
	}
	return MarketOrderStatus_MARKET_ORDER_INACTIVE
}

func (m *MarketOrder) GetAuthorID() string {
	if m != nil {
		return m.AuthorID
	}
	return ""
}

func (m *MarketOrder) GetCounterpartyID() string {
	if m != nil {
		return m.CounterpartyID
	}
	return ""
}

func (m *MarketOrder) GetDuration() uint64 {
	if m != nil {
		return m.Duration
	}
	return 0
}

func (m *MarketOrder) GetPrice() *BigInt {
	if m != nil {
		return m.Price
	}
	return nil
}

func (m *MarketOrder) GetNetflags() uint64 {
	if m != nil {
		return m.Netflags
	}
	return 0
}

func (m *MarketOrder) GetIdentityLevel() MarketIdentityLevel {
	if m != nil {
		return m.IdentityLevel
	}
	return MarketIdentityLevel_MARKET_ANONIMOUS
}

func (m *MarketOrder) GetBlacklist() string {
	if m != nil {
		return m.Blacklist
	}
	return ""
}

func (m *MarketOrder) GetTag() []byte {
	if m != nil {
		return m.Tag
	}
	return nil
}

func (m *MarketOrder) GetBenchmarks() []uint64 {
	if m != nil {
		return m.Benchmarks
	}
	return nil
}

func (m *MarketOrder) GetFrozenSum() *BigInt {
	if m != nil {
		return m.FrozenSum
	}
	return nil
}

func init() {
	proto.RegisterType((*GetOrdersRequest)(nil), "sonm.GetOrdersRequest")
	proto.RegisterType((*GetOrdersReply)(nil), "sonm.GetOrdersReply")
	proto.RegisterType((*MarketDeal)(nil), "sonm.MarketDeal")
	proto.RegisterType((*MarketOrder)(nil), "sonm.MarketOrder")
	proto.RegisterEnum("sonm.MarketOrderType", MarketOrderType_name, MarketOrderType_value)
	proto.RegisterEnum("sonm.MarketOrderStatus", MarketOrderStatus_name, MarketOrderStatus_value)
	proto.RegisterEnum("sonm.MarketIdentityLevel", MarketIdentityLevel_name, MarketIdentityLevel_value)
	proto.RegisterEnum("sonm.MarketDealStatus", MarketDealStatus_name, MarketDealStatus_value)
	proto.RegisterEnum("sonm.MarketChangeRequestStatus", MarketChangeRequestStatus_name, MarketChangeRequestStatus_value)
}

// Reference imports to suppress errors if they are not otherwise used.
var _ context.Context
var _ grpc.ClientConn

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
const _ = grpc.SupportPackageIsVersion4

// Client API for Market service

type MarketClient interface {
	// GetOrders returns orders by given filter parameters.
	// Note that set of filters may be changed in the closest future.
	GetOrders(ctx context.Context, in *GetOrdersRequest, opts ...grpc.CallOption) (*GetOrdersReply, error)
	// CreateOrder places new order on the Marketplace.
	// Note that current impl of Node API prevents you from
	// creating ASKs orders.
	CreateOrder(ctx context.Context, in *MarketOrder, opts ...grpc.CallOption) (*MarketOrder, error)
	// GetOrderByID returns order by given ID.
	// If order save an `inactive` status returns error instead.
	GetOrderByID(ctx context.Context, in *ID, opts ...grpc.CallOption) (*MarketOrder, error)
	// CancelOrder removes active order from the Marketplace.
	CancelOrder(ctx context.Context, in *ID, opts ...grpc.CallOption) (*Empty, error)
}

type marketClient struct {
	cc *grpc.ClientConn
}

func NewMarketClient(cc *grpc.ClientConn) MarketClient {
	return &marketClient{cc}
}

func (c *marketClient) GetOrders(ctx context.Context, in *GetOrdersRequest, opts ...grpc.CallOption) (*GetOrdersReply, error) {
	out := new(GetOrdersReply)
	err := grpc.Invoke(ctx, "/sonm.Market/GetOrders", in, out, c.cc, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *marketClient) CreateOrder(ctx context.Context, in *MarketOrder, opts ...grpc.CallOption) (*MarketOrder, error) {
	out := new(MarketOrder)
	err := grpc.Invoke(ctx, "/sonm.Market/CreateOrder", in, out, c.cc, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *marketClient) GetOrderByID(ctx context.Context, in *ID, opts ...grpc.CallOption) (*MarketOrder, error) {
	out := new(MarketOrder)
	err := grpc.Invoke(ctx, "/sonm.Market/GetOrderByID", in, out, c.cc, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *marketClient) CancelOrder(ctx context.Context, in *ID, opts ...grpc.CallOption) (*Empty, error) {
	out := new(Empty)
	err := grpc.Invoke(ctx, "/sonm.Market/CancelOrder", in, out, c.cc, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Server API for Market service

type MarketServer interface {
	// GetOrders returns orders by given filter parameters.
	// Note that set of filters may be changed in the closest future.
	GetOrders(context.Context, *GetOrdersRequest) (*GetOrdersReply, error)
	// CreateOrder places new order on the Marketplace.
	// Note that current impl of Node API prevents you from
	// creating ASKs orders.
	CreateOrder(context.Context, *MarketOrder) (*MarketOrder, error)
	// GetOrderByID returns order by given ID.
	// If order save an `inactive` status returns error instead.
	GetOrderByID(context.Context, *ID) (*MarketOrder, error)
	// CancelOrder removes active order from the Marketplace.
	CancelOrder(context.Context, *ID) (*Empty, error)
}

func RegisterMarketServer(s *grpc.Server, srv MarketServer) {
	s.RegisterService(&_Market_serviceDesc, srv)
}

func _Market_GetOrders_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(GetOrdersRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MarketServer).GetOrders(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/sonm.Market/GetOrders",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MarketServer).GetOrders(ctx, req.(*GetOrdersRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Market_CreateOrder_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(MarketOrder)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MarketServer).CreateOrder(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/sonm.Market/CreateOrder",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MarketServer).CreateOrder(ctx, req.(*MarketOrder))
	}
	return interceptor(ctx, in, info, handler)
}

func _Market_GetOrderByID_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ID)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MarketServer).GetOrderByID(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/sonm.Market/GetOrderByID",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MarketServer).GetOrderByID(ctx, req.(*ID))
	}
	return interceptor(ctx, in, info, handler)
}

func _Market_CancelOrder_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ID)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MarketServer).CancelOrder(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/sonm.Market/CancelOrder",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MarketServer).CancelOrder(ctx, req.(*ID))
	}
	return interceptor(ctx, in, info, handler)
}

var _Market_serviceDesc = grpc.ServiceDesc{
	ServiceName: "sonm.Market",
	HandlerType: (*MarketServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "GetOrders",
			Handler:    _Market_GetOrders_Handler,
		},
		{
			MethodName: "CreateOrder",
			Handler:    _Market_CreateOrder_Handler,
		},
		{
			MethodName: "GetOrderByID",
			Handler:    _Market_GetOrderByID_Handler,
		},
		{
			MethodName: "CancelOrder",
			Handler:    _Market_CancelOrder_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "marketplace.proto",
}

// Begin grpccmd
var _ = grpccmd.RunE

// Market
var _MarketCmd = &cobra.Command{
	Use:   "market [method]",
	Short: "Subcommand for the Market service.",
}

var _Market_GetOrdersCmd = &cobra.Command{
	Use:   "getOrders",
	Short: "Make the GetOrders method call, input-type: sonm.GetOrdersRequest output-type: sonm.GetOrdersReply",
	RunE: grpccmd.RunE(
		"GetOrders",
		"sonm.GetOrdersRequest",
		func(c io.Closer) interface{} {
			cc := c.(*grpc.ClientConn)
			return NewMarketClient(cc)
		},
	),
}

var _Market_GetOrdersCmd_gen = &cobra.Command{
	Use:   "getOrders-gen",
	Short: "Generate JSON for method call of GetOrders (input-type: sonm.GetOrdersRequest)",
	RunE:  grpccmd.TypeToJson("sonm.GetOrdersRequest"),
}

var _Market_CreateOrderCmd = &cobra.Command{
	Use:   "createOrder",
	Short: "Make the CreateOrder method call, input-type: sonm.MarketOrder output-type: sonm.MarketOrder",
	RunE: grpccmd.RunE(
		"CreateOrder",
		"sonm.MarketOrder",
		func(c io.Closer) interface{} {
			cc := c.(*grpc.ClientConn)
			return NewMarketClient(cc)
		},
	),
}

var _Market_CreateOrderCmd_gen = &cobra.Command{
	Use:   "createOrder-gen",
	Short: "Generate JSON for method call of CreateOrder (input-type: sonm.MarketOrder)",
	RunE:  grpccmd.TypeToJson("sonm.MarketOrder"),
}

var _Market_GetOrderByIDCmd = &cobra.Command{
	Use:   "getOrderByID",
	Short: "Make the GetOrderByID method call, input-type: sonm.ID output-type: sonm.MarketOrder",
	RunE: grpccmd.RunE(
		"GetOrderByID",
		"sonm.ID",
		func(c io.Closer) interface{} {
			cc := c.(*grpc.ClientConn)
			return NewMarketClient(cc)
		},
	),
}

var _Market_GetOrderByIDCmd_gen = &cobra.Command{
	Use:   "getOrderByID-gen",
	Short: "Generate JSON for method call of GetOrderByID (input-type: sonm.ID)",
	RunE:  grpccmd.TypeToJson("sonm.ID"),
}

var _Market_CancelOrderCmd = &cobra.Command{
	Use:   "cancelOrder",
	Short: "Make the CancelOrder method call, input-type: sonm.ID output-type: sonm.Empty",
	RunE: grpccmd.RunE(
		"CancelOrder",
		"sonm.ID",
		func(c io.Closer) interface{} {
			cc := c.(*grpc.ClientConn)
			return NewMarketClient(cc)
		},
	),
}

var _Market_CancelOrderCmd_gen = &cobra.Command{
	Use:   "cancelOrder-gen",
	Short: "Generate JSON for method call of CancelOrder (input-type: sonm.ID)",
	RunE:  grpccmd.TypeToJson("sonm.ID"),
}

// Register commands with the root command and service command
func init() {
	grpccmd.RegisterServiceCmd(_MarketCmd)
	_MarketCmd.AddCommand(
		_Market_GetOrdersCmd,
		_Market_GetOrdersCmd_gen,
		_Market_CreateOrderCmd,
		_Market_CreateOrderCmd_gen,
		_Market_GetOrderByIDCmd,
		_Market_GetOrderByIDCmd_gen,
		_Market_CancelOrderCmd,
		_Market_CancelOrderCmd_gen,
	)
}

// End grpccmd

func init() { proto.RegisterFile("marketplace.proto", fileDescriptor10) }

var fileDescriptor10 = []byte{
	// 935 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0x74, 0x55, 0xcf, 0x6f, 0xe2, 0x46,
	0x14, 0xc6, 0xc4, 0x21, 0xf1, 0x83, 0x10, 0x67, 0x42, 0xb2, 0x0e, 0xaa, 0x2a, 0xc4, 0x61, 0x45,
	0x90, 0x96, 0x4a, 0xec, 0xf6, 0x50, 0xed, 0xa1, 0x02, 0xdb, 0x5d, 0xb9, 0x49, 0x20, 0x1d, 0x9b,
	0x56, 0xab, 0x1e, 0xa2, 0xc1, 0x9e, 0x25, 0x56, 0x8c, 0xed, 0xda, 0x43, 0x25, 0x7a, 0xec, 0xa5,
	0x7f, 0x49, 0x8f, 0xfd, 0x6b, 0xfa, 0x0f, 0xad, 0x3c, 0x36, 0x30, 0xfc, 0xc8, 0x8d, 0xf7, 0x7d,
	0x1f, 0xf3, 0xde, 0xbc, 0xf9, 0x9e, 0x1f, 0x5c, 0xcc, 0x49, 0xf2, 0x42, 0x59, 0x1c, 0x10, 0x97,
	0xf6, 0xe2, 0x24, 0x62, 0x11, 0x92, 0xd3, 0x28, 0x9c, 0x37, 0x6b, 0x53, 0x7f, 0xe6, 0x87, 0x2c,
	0xc7, 0x9a, 0xe7, 0x7e, 0x98, 0xa1, 0xa1, 0x4f, 0x56, 0x00, 0xf3, 0xe7, 0x34, 0x65, 0x64, 0x1e,
	0xe7, 0x40, 0xfb, 0x3f, 0x09, 0xd4, 0x4f, 0x94, 0x8d, 0x13, 0x8f, 0x26, 0x29, 0xa6, 0x7f, 0x2c,
	0x68, 0xca, 0xd0, 0x2d, 0xc8, 0x6c, 0x19, 0x53, 0x4d, 0x6a, 0x49, 0x9d, 0x7a, 0xff, 0xaa, 0x97,
	0x9d, 0xd1, 0x7b, 0xe0, 0x19, 0xb9, 0xd0, 0x59, 0xc6, 0x14, 0x73, 0x09, 0x6a, 0xc3, 0xf1, 0x63,
	0xe2, 0xbb, 0x54, 0x2b, 0xb7, 0xa4, 0x4e, 0xb5, 0x5f, 0xcb, 0xb5, 0x43, 0x7f, 0x66, 0x85, 0x0c,
	0xe7, 0x14, 0xfa, 0x00, 0x35, 0x3d, 0x5a, 0x84, 0x8c, 0x26, 0x31, 0x49, 0xd8, 0x52, 0x3b, 0xe2,
	0x52, 0x35, 0x97, 0x9a, 0xec, 0x79, 0xe0, 0x79, 0x09, 0x4d, 0x53, 0xbc, 0xa5, 0x42, 0x0d, 0x38,
	0x76, 0xb3, 0x58, 0x93, 0x5b, 0x52, 0x47, 0xc6, 0x79, 0xd0, 0xfe, 0x08, 0x75, 0xa1, 0xdc, 0x38,
	0x58, 0xa2, 0x5b, 0xa8, 0x44, 0x3c, 0xd4, 0xa4, 0xd6, 0x51, 0xa7, 0xda, 0xbf, 0xd8, 0x2b, 0x17,
	0x17, 0x82, 0xf6, 0xbf, 0x32, 0x40, 0x8e, 0x1b, 0x94, 0x04, 0xa8, 0x0e, 0x65, 0xdf, 0xe3, 0x97,
	0x54, 0x70, 0xd9, 0xf7, 0xd0, 0xb7, 0x00, 0x53, 0x1a, 0xba, 0xcf, 0x59, 0x6f, 0x53, 0xad, 0xdc,
	0x3a, 0xea, 0xc8, 0x58, 0x40, 0x32, 0x3e, 0x5d, 0xc4, 0x71, 0xe0, 0xd3, 0xc4, 0x32, 0xf8, 0x2d,
	0x14, 0x2c, 0x20, 0x19, 0xef, 0x46, 0x61, 0xba, 0x98, 0x73, 0x5e, 0xce, 0xf9, 0x0d, 0x82, 0x9a,
	0x70, 0x3a, 0x27, 0x29, 0xe3, 0xec, 0x31, 0x67, 0xd7, 0x71, 0x76, 0x5b, 0x92, 0xbe, 0x58, 0x86,
	0x56, 0xe1, 0x44, 0x1e, 0x64, 0xe8, 0xd4, 0xf7, 0x2c, 0x43, 0x3b, 0xc9, 0x51, 0x1e, 0x64, 0xe7,
	0x78, 0x8b, 0x84, 0x30, 0x3f, 0x0a, 0xb5, 0x53, 0xde, 0x9c, 0x75, 0x9c, 0xbd, 0x47, 0xcc, 0xdf,
	0x43, 0x39, 0xf4, 0x1e, 0x9c, 0x42, 0xef, 0x40, 0x49, 0x19, 0x49, 0x98, 0xe3, 0xcf, 0xa9, 0x06,
	0x5c, 0x77, 0x9e, 0xeb, 0x9c, 0x95, 0x3b, 0xf0, 0x46, 0x81, 0x6e, 0xe1, 0x84, 0x86, 0x1e, 0x17,
	0x57, 0x0f, 0x8b, 0x57, 0x3c, 0xea, 0x41, 0x25, 0x65, 0x84, 0x2d, 0x52, 0xad, 0xc6, 0xad, 0x73,
	0x2d, 0xbe, 0x45, 0xd6, 0x73, 0x9b, 0xb3, 0xb8, 0x50, 0xa1, 0x0f, 0x50, 0x9f, 0x06, 0x91, 0xfb,
	0x42, 0xbd, 0x21, 0x09, 0x48, 0xe8, 0x52, 0xed, 0xec, 0x40, 0xd9, 0x3b, 0x1a, 0xd4, 0x83, 0x2a,
	0x8b, 0x18, 0x09, 0x1e, 0xc9, 0x32, 0x5a, 0x30, 0xad, 0x7e, 0xe0, 0x2f, 0xa2, 0x00, 0x7d, 0x07,
	0x10, 0x90, 0x94, 0x0d, 0xfd, 0x20, 0x70, 0x6c, 0xed, 0xfc, 0xf0, 0x1d, 0x04, 0x49, 0xfb, 0x6f,
	0x19, 0xaa, 0x82, 0x7f, 0xf6, 0x8c, 0x72, 0x0d, 0x15, 0x8f, 0x92, 0xc0, 0x32, 0xb8, 0xeb, 0x15,
	0x5c, 0x44, 0xe8, 0x3d, 0x28, 0xd1, 0x6a, 0x3e, 0xb8, 0x3f, 0x5e, 0x1d, 0x9e, 0x8d, 0x0e, 0xfd,
	0x00, 0x55, 0x1e, 0xe4, 0xad, 0xe1, 0xb6, 0xa9, 0xf7, 0xdf, 0xec, 0xfd, 0xad, 0xe8, 0x9c, 0xa8,
	0xcd, 0x8c, 0x40, 0x16, 0xec, 0x39, 0x12, 0x0c, 0xb5, 0x8a, 0xd1, 0x5b, 0xa8, 0xbb, 0xc2, 0x38,
	0xad, 0x9d, 0xb5, 0x83, 0x6e, 0x99, 0xe9, 0xe4, 0x35, 0x33, 0x9d, 0xbe, 0x6e, 0xa6, 0x26, 0x9c,
	0x86, 0x94, 0x7d, 0x09, 0xc8, 0x2c, 0xe5, 0x9e, 0x93, 0xf1, 0x3a, 0x46, 0x3f, 0xc2, 0x99, 0xef,
	0xd1, 0x90, 0xf9, 0x6c, 0x79, 0x4f, 0xff, 0xa4, 0x01, 0x37, 0x5b, 0xbd, 0x7f, 0x23, 0x5e, 0xce,
	0x12, 0x05, 0x78, 0x5b, 0x8f, 0xbe, 0x01, 0x65, 0x1a, 0x10, 0xf7, 0x25, 0xf0, 0x53, 0xc6, 0xcd,
	0xa7, 0xe0, 0x0d, 0x80, 0x54, 0x38, 0x62, 0x64, 0xc6, 0xad, 0x56, 0xc3, 0xd9, 0xcf, 0x9d, 0x09,
	0x3e, 0xdb, 0x9b, 0xe0, 0x2e, 0x28, 0x5f, 0x92, 0xe8, 0x2f, 0x1a, 0xda, 0x8b, 0xf9, 0x41, 0xdf,
	0x6c, 0xe8, 0xee, 0x00, 0xce, 0x77, 0x5e, 0x0d, 0xd5, 0x01, 0x1e, 0x06, 0xf8, 0xce, 0x74, 0x9e,
	0x06, 0xa3, 0xcf, 0x6a, 0x49, 0x88, 0x87, 0x96, 0xa1, 0x4a, 0x22, 0x6f, 0xdf, 0xa9, 0xe5, 0xee,
	0x27, 0xb8, 0xd8, 0x7b, 0x41, 0x74, 0x03, 0x57, 0x85, 0x68, 0x8c, 0x0d, 0x13, 0x3f, 0x59, 0xa3,
	0x81, 0xee, 0x58, 0xbf, 0x9a, 0x6a, 0x09, 0xbd, 0x81, 0xcb, 0x2d, 0xaa, 0x20, 0xa4, 0xee, 0xef,
	0x70, 0x79, 0xa0, 0x5b, 0xa8, 0x01, 0xea, 0xba, 0x9e, 0xf1, 0xc8, 0x7a, 0x18, 0x4f, 0xec, 0xad,
	0x53, 0x1e, 0x6d, 0x73, 0x62, 0x8c, 0x47, 0x9f, 0x39, 0x21, 0xa1, 0x2b, 0xb8, 0x28, 0x08, 0xcb,
	0x30, 0x47, 0x8e, 0xf5, 0x93, 0x65, 0x1a, 0x6a, 0xb9, 0xeb, 0x82, 0xba, 0x3b, 0xa0, 0x42, 0x91,
	0xb6, 0x33, 0x70, 0x26, 0xf6, 0xd3, 0x64, 0x74, 0x37, 0x1a, 0xff, 0x36, 0x52, 0x4b, 0xa8, 0x09,
	0xd7, 0xdb, 0xd4, 0x40, 0xd7, 0xcd, 0x47, 0xc7, 0xcc, 0x1a, 0xa0, 0x41, 0x63, 0x9b, 0xd3, 0xef,
	0xc7, 0x36, 0x4f, 0xf2, 0x8f, 0x04, 0x37, 0x79, 0x16, 0xfd, 0x99, 0x84, 0x33, 0x5a, 0xac, 0x9a,
	0x22, 0xdd, 0x25, 0x9c, 0x63, 0xf3, 0x97, 0x89, 0x69, 0x3b, 0x42, 0x22, 0x01, 0xd4, 0xb1, 0x39,
	0xc8, 0x33, 0x34, 0x40, 0x5d, 0x83, 0x83, 0x91, 0x6e, 0xde, 0x67, 0xa7, 0x8b, 0x28, 0x36, 0x7f,
	0x36, 0xf5, 0x4c, 0x7b, 0x24, 0xa2, 0xeb, 0x1a, 0xe5, 0xfe, 0xff, 0x12, 0x54, 0xf2, 0x4a, 0xd0,
	0x47, 0x50, 0xd6, 0xcb, 0x04, 0x15, 0xdf, 0xaa, 0xdd, 0x65, 0xd8, 0x6c, 0xec, 0xe1, 0x71, 0xb0,
	0x6c, 0x97, 0xd0, 0xf7, 0x50, 0xd5, 0x13, 0x4a, 0x18, 0xcd, 0xbf, 0x11, 0xfb, 0x6b, 0xa7, 0xb9,
	0x0f, 0xb5, 0x4b, 0xe8, 0x1d, 0xd4, 0x56, 0x47, 0x0d, 0xb3, 0xf9, 0x3b, 0xcd, 0x45, 0x96, 0x71,
	0x58, 0xfe, 0x16, 0xaa, 0x7a, 0xf6, 0xd1, 0x0b, 0xf2, 0x2c, 0x1b, 0x75, 0xb5, 0x58, 0x9f, 0xf3,
	0x98, 0x2d, 0xdb, 0xa5, 0x69, 0x85, 0xaf, 0xf3, 0xf7, 0x5f, 0x03, 0x00, 0x00, 0xff, 0xff, 0xec,
	0x55, 0x0c, 0x15, 0x19, 0x08, 0x00, 0x00,
}
