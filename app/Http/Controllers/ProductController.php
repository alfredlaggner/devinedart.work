<?php

namespace App\Http\Controllers;

use App\Product;
use App\Category2;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\View;

class ProductController extends Controller
    {
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */



        public function index()
            {
                $products = Product::where('is_archive', '==', '0')->orderby('merchant_product_id')->paginate(15);
                return view('products',['products' => $products]);

            }

        public function secondary()
            {
                $products = Category2::find(1)->cat2;
                foreach ($products as $product) {
                    echo $product->product_id . "<br>";
                }

            }

        function getImage($product_id)
            {
                $image = [''];
                $skus = Product::findOrFail($product_id)->images;
                $imageAddress = "cw4/images/orig/";
                foreach ($skus as $sku) {
                    if ($sku->imagetype_id == 3) {
                        return $imageAddress . $sku->filename;
                    }
                }
                return NULL;
            }

        function getImage2($product_id)
            {
                $image = [''];
                $skus = Product::findOrFail($product_id)->images;
                $imageAddress = "http://www.illuminearts.com/cw4/images/orig/";
                foreach ($skus as $sku) {
                    if ($sku->imagetype_id == 11) {
                        return $imageAddress . $sku->filename;
                    }
                }
                return NULL;
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
