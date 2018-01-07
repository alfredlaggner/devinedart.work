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

Route::view('/welcome', 'index');

Auth::routes();
Route::get('/test1','ProductController@index');
Route::get('/', ['as' =>'uploads', 'uses' => 'HomeController@index']);

Route::get('/import/products',['as' =>'product_upload', 'uses' => 'ProductUploadController@products_2_shopify']);

Route::get('/import/original',['as' =>'original_upload', 'uses' => 'ProductUploadController@original_2_import']);

Route::get('/import/customers',['as' =>'customer_upload', 'uses' => 'CustomerUploadController@customers_2_shopify']);

Route::get('/import/wholesale','ProductUploadController@update_wholesale');

Route::get('/secprod', 'ProductController@secondary');

Route::resource('products', 'ProductController');

Route::resource('/secondary', 'CategorySecondaryController');

Auth::routes();

Route::get('makecsv','ProductUploadController@export_csv');
Route::get('/cleanup','ProductUploadController@clean_description');
Route::get('/cleanup2','ProductUploadController@makeSkuSize');
Route::get('/test','ProductUploadController@test');

