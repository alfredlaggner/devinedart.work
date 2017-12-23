<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/


Auth::routes();

Route::get('/', ['as' =>'uploads', 'uses' => 'HomeController@index']);

Route::get('/import/products',['as' =>'product_upload', 'uses' => 'ProductUploadController@products_2_shopify']);

Route::get('/import/original',['as' =>'original_upload', 'uses' => 'ProductUploadController@original_2_import']);

Route::get('/import/customers',['as' =>'customer_upload', 'uses' => 'CustomerUploadController@customers_2_shopify']);

Route::get('/secprod', 'ProductController@secondary');

Route::resource('products', 'ProductController');
Route::resource('/secondary', 'CategorySecondaryController');

Auth::routes();


Route::get('makeupload','ProductUploadController@export_csv');
Route::get('/cleanup','ProductUploadController@clean_description');
Route::get('/cleanup2','ProductUploadController@makeSkuSize');