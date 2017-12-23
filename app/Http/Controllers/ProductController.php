<?php

namespace App\Http\Controllers;

use App\Product;
use App\Category2;
use Illuminate\Http\Request;

class ProductController extends Controller
    {
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */

        public function index()
            {
                $secundary =
    //            $products = Product::all();
                $products = Product::where('is_archive','==', '0')->orderby('merchant_product_id')->paginate(15);
                return view('products',['products' => $products]);

            }

            public function secondary(){
                $products = Category2::find(1)->cat2;
               dd($products);
                foreach($products as $product) {
                    echo $product->product_id . "<br>";
                }

            }


    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
        public function create()
            {
                //
            }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request $request
     * @return \Illuminate\Http\Response
     */
        public function store(Request $request)
            {
                //
            }

    /**
     * Display the specified resource.
     *
     * @param  \App\Product $product
     * @return \Illuminate\Http\Response
     */
        public function show(Product $product)
            {
                //
            }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Product $product
     * @return \Illuminate\Http\Response
     */
        public function edit(Product $product)
            {
                //
            }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request $request
     * @param  \App\Product $product
     * @return \Illuminate\Http\Response
     */
        public function update(Request $request, Product $product)
            {
                //
            }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Product $product
     * @return \Illuminate\Http\Response
     */
        public function destroy(Product $product)
            {
                //
            }

    }
