@extends('layouts.app')
@section('content')
    <div class="container">
        @foreach ($category as $cat)
            <div class="col-sm-3">
                <div class="card">
                    <img class="card-img-top" src="..." alt="Card image cap">
                    <div class="card-body">
                        <h4 class="card-title">{{$cat->name}}</h4>
                        <h6 class="card-subtitle mb-2 text-muted">{{$cat->id}}</h6>
                        <p class="card-text"></p>
                    </div>
                </div>
            </div>
        @endforeach
    </div>
@endsection


