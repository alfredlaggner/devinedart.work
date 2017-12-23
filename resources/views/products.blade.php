@extends('layouts.app')
@section('content')
    <div class="container">
        @foreach ($products->chunk(4) as $chunks)
            <div class="row" style="margin-top: 1rem">
                @foreach ($chunks as $product)
                    <div class="col-sm-3">
                        <div class="card">
                            <img class="card-img-top" src="..." alt="Card image cap">
                            <div class="card-body">
                                <h4 class="card-title">{{$product->product_name}}</h4>
                                <h6 class="card-subtitle mb-2 text-muted">{{$product->id}}</h6>
                                <p class="card-text"></p>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        @endforeach
            {{ $products->links() }}
    </div>
@endsection


