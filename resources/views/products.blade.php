@extends('layouts.app')
@section('content')
    <div class="container">
        @foreach ($products->chunk(4) as $chunks)

            <div class="row" style="margin-top: 1rem">
                @foreach ($chunks as $product)
                    <div class="col-lg-3 d-flex align-items-stretch">
                        <div class="card">
                            <h6 class="card-title">{{$product->name}}</h6>
                            <img class="card-img-top" src="http://www.illuminearts.com/cw4/images/orig/{{$product->image}}" alt="Card image cap1">
                            <div class="card-body">
                                <h6 class="card-subtitle mb-2 text-muted"></h6>
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


