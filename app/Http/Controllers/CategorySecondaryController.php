<?php

namespace App\Http\Controllers;

use App\Category2;
use Illuminate\Http\Request;

class CategorySecondaryController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        $secondaries =Category2::find(11)->prods2;
  //      dd($secondaries);
        return view('secondary',['secondaries' => $secondaries]);

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
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Category_2  $category_secundary
     * @return \Illuminate\Http\Response
     */
    public function show(Category_2 $category_secundary)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Category_2  $category_secundary
     * @return \Illuminate\Http\Response
     */
    public function edit(Category_2 $category_secundary)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Category_2  $category_secundary
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Category_2 $category_secundary)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Category_2  $category_secundary
     * @return \Illuminate\Http\Response
     */
    public function destroy(Category_2 $category_secundary)
    {
        //
    }
}
