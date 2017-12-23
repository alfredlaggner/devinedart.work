@extends('layouts.app')
@section('content')
    <div class="container">

        <div class="row mt-6">
            <div class="col-md-8 offset-md-2">
                <div class="card">
                    <div class="card-header">Shopify Upload</div>

                    <div class="card-body">
                        <ul>
                            <li><a href="{{ URL::route('original_upload')}}">Original Upload </a> </li>
                            <li><a href="{{ URL::route('product_upload')}}">Product Upload </a> </li>
                            <li><a href="{{ URL::route('customer_upload')}}">Customer Upload </a> </li>
                        </ul>

                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection;
