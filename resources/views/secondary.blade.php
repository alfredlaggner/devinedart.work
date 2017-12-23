@extends('layouts.app')

@section('content')
    <div class="container">
        <div class="row">
            <div class="col-md-8 col-md-offset-2">
                <div class="panel panel-default">
                    <div class="panel-heading">secondary</div>

                    <div class="panel-body">
                        @foreach ($secondaries as $second)
                            <p>
                                {{$second->id}},
                                {{$second->product_name}},
                            </p>
                        @endforeach
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
