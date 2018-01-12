<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use App\Cw_product;
use App\Product;
use App\WholesaleProduct;
use App\WholesalePhoto;
use App\WholesaleInventory;
use App\Sku;
use App\Cw_sku;
use App\Category1;
use App\Category2;
use App\Category1_product;
use App\Category2_product;
use App\Product_image;
use App\Cw_categories_primary;
use App\Cw_categories_secondary;
use App\Cw_product_categories_primary;
use App\Cw_product_categories_secondary;
use App\Cw_product_image;
use App\Shopify_import;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Database\Eloquent\ModelNotFoundException;

ini_set('max_execution_time', 180 * 2); //6 minutes

class ProductUploadController extends Controller
    {


        public function test()
            {
                $cw_product = Cw_product::first();
                echo $cw_product->product_name;
                die();

            }

        function getProductImage($product_id)
            {
                $image = [''];
                $skus = Product::findOrFail($product_id)->images;
                foreach ($skus as $sku) {
                    if ($sku->imagetype_id == 3) {
                        return $sku->filename;
                    }
                }
                return NULL;
            }

        public function org_test()
            {
                $product = Product::whereDate('date_modified', '<=', '2017-12-20')->get();
                //         $product = Product::get();
                //          dd($product);

                foreach ($product as $p) {
                    $p->name = $p->cw_product->product_name;
                    echo $p->name . "<br>";
                    $p->description = $p->cw_product->product_description;
                    $p->preview_description = $p->cw_product->product_preview_description;
                    $p->is_on_web = $p->cw_product->product_on_web;
                    $p->is_archive = $p->cw_product->product_archive;
                    $p->date_modified = $p->cw_product->product_date_modified;
                    $p->special_description = $p->cw_product->product_special_description;
                    $p->keywords = $p->cw_product->product_keywords;
                    $p->update();
                }
            }


        function getCat2()
            {
                $query = DB::table('products')
                    ->join('cw_product_categories_secondary', 'product_id', '=', 'product2secondary_product_id')
                    ->select('products.*', 'cw_product_categories_secondary.product2secondary_secondary_id')
                    ->update(['category2_id' => 'cw_product_categories_secondary.product2secondary_secondary_id']);
                /*                foreach ($query as $row)
                                {
                                    $category2_id = $row->product2secondary_secondary_id;
                                    update($row->category2_id = $category2_id);
                                }*/
            }

        public function update_wholesale()
            {
                Schema::connection("wholesale")->drop('products');

                Schema::connection("wholesale")->create('products',
                    function (Blueprint $table) {
                        $table->integer('tmp_product_id')->nullable();
                        $table->string('name', 255)->nullable();
                        $table->string('uri', 255)->nullable();
                        $table->text('description')->nullable();
                        $table->float('price', 8, 2)->nullable();
                        $table->float('old_price', 8, 2)->nullable();
                        $table->integer('category_id')->nullable();
                        $table->integer('special')->nullable();
                        $table->integer('new')->nullable();
                        $table->integer('order')->nullable();
                        $table->text('type')->nullable();
                        $table->string('merchant_product_id', 255)->nullable();
                        $table->text('preview_description')->nullable();
                        $table->integer('sort')->nullable();
                        $table->boolean('is_on_web')->nullable();
                        $table->boolean('is_archive')->nullable();
                        $table->boolean('is_ship_charge')->nullable();
                        $table->integer('tax_group_id')->nullable();
                        $table->date('date_modified')->nullable();
                        $table->string('special_description', 255)->nullable();
                        $table->text('keywords')->nullable();
                        $table->text('out_of_stock_message')->nullable();
                        $table->text('custom_info_label')->nullable();
                        $table->timestamps();
                    });

                $products = Product::get();

                foreach ($products as $p) {

                    WholesaleProduct::FirstOrcreate(
                        [
                            //    'id' => $p->product_id,
                            'tmp_product_id' => $p->product_id,
                            'name' => $p->name,
                            'uri' => str_replace(' ', '-',
                                str_replace('"', '',
                                    strtolower(rtrim($p->name)))),
                            'description' => $p->description,
                            'price' => $this->getPrice($p->id, 0),
                            'old_price' => $this->getPrice($p->id, 0),
                            'category_id' => 0,
                            'special' => false,
                            'new' => false,
                            'order' => $p->sort,
                            'type' => $p->type,
                            'merchant_product_id' => $p->merchant_product_id,
                            'preview_description' => $p->preview_description,
                            'is_on_web' => $p->is_on_web,
                            'is_archive' => $p->is_archive,
                            'is_ship_charge' => $p->is_ship_charge,
                            'tax_group_id' => $p->tax_group_id,
                            'date_modified' => $p->date_modified,
                            'special_description' => $p->special_description,
                            'keywords' => $p->keywords,
                            'out_of_stock_message' => $p->out_of_stock_message,
                            'custom_info_label' => $p->custom_info_label,
                        ]);
                }

                Schema::connection("wholesale")->table('products',
                    function (Blueprint $table) {

                        $table->renameColumn('tmp_product_id', 'id')->nullable(false)
                            ->autoIncrement();
                        $table->primary('id');

                    });



                DB::connection("wholesale")->table('photos')->truncate();
                $photos = Product_image::get();

                foreach ($photos as $p) {

                    WholesalePhoto::Create(
                        [
                            'product_id' => $p->product_id,
                            'name' => $p->filename,
                            'original_name' => $p->filename,
                            'order' => 0,
                            'default' => 0,
                            'imagetype_id' => $p->imagetype_id,
                            'caption' => $p->caption,
                        ]);

                }
                $photos = ['default' => 1, 'order' => 1];
                WholesalePhoto::where('imagetype_id', '=', 3)->update($photos);

                $photos = ['default' => 0, 'order' => 2];
                WholesalePhoto::where('imagetype_id', '=', 11)->update($photos);


                echo "done 1";


                $photos = WholesalePhoto::where('imagetype_id', '=', 11)->get();

                foreach ($photos as $p) {
                    echo $p->imagetype_id . "<br>";

                    $p->default = 0;
                    $p->order = 2;
                    $p->save();
                };

                $photos = WholesalePhoto::where('order', '=', 0)->get();

                foreach ($photos as $p) {

                    $p->forceDelete();
                };



                DB::connection("wholesale")->table('inventory')->truncate();
                $inventory = Sku::get();

                foreach ($inventory as $p) {

                    WholesaleInventory::FirstOrcreate(
                        ['sku' => $p->merchant_sku_id,
                            'product_id' => $p->product_id,
                            'price' => $p->price / 2,
                            'stock' => $p->stock,
                            'order' => $p->sort,
                            'weight' => $p->weight,
                            'on_web' => $p->on_web,
                            'alt_price' => $p->price,
                            'ship_base' => $p->ship_base,]);
                }

                dd(" all done");
            }

        public
        function original_2_import()
            {
                echo "Importing product table <br>";

                DB::table('products')->truncate();

                $cw_products = Cw_Product::where('product_date_modified', '>=', '2017-12-15')->get();

                foreach ($cw_products as $cw) {

                    Product::updateOrcreate(
                        [
                            'product_id' => $cw->product_id,
                            'name' => $cw->product_name,
                            'description' => $cw->product_description,
                            'merchant_product_id' => $cw->product_merchant_product_id,
                            'preview_description' => $cw->product_preview_description,
                            'sort' => $cw->product_sort,
                            'is_on_web' => $cw->product_on_web,
                            'is_archive' => $cw->product_archive,
                            'is_ship_charge' => $cw->product_is_ship_charge,
                            'tax_group_id' => $cw->product_tax_group_id,
                            'date_modified' => $cw->product_date_modified,
                            'special_description' => $cw->product_special_description,
                            'keywords' => $cw->product_keywords,
                            'out_of_stock_message' => $cw->product_out_of_stock_message,
                            'custom_info_label' => $cw->product_custom_info_label,
                            //             'category2_id' => $this->getCat2($cw->product_id),
                        ]);

                    $query = DB::table('products')
                        ->Join('cw_product_categories_primary', 'product_id', '=', 'product2category_product_id')
                        ->select('products.*', 'cw_product_categories_primary.*')
                        ->get();
                    foreach ($query as $row) {
                        DB::table('products')
                            ->where('id', $row->id)
                            ->update(['category1_id' => $row->product2category_category_id]);
                    };

                    $query = DB::table('products')
                        ->Join('cw_product_categories_secondary', 'product_id', '=', 'product2secondary_product_id')
                        ->select('products.*', 'cw_product_categories_secondary.*')
                        ->get();
                    foreach ($query as $row) {
                        DB::table('products')
                            ->where('id', $row->id)
                            ->update(['category2_id' => $row->product2secondary_secondary_id]);
                    };


                }


                echo "Importing images <br>";

                DB::table('product_images')->truncate();

                $cw_product_images = Cw_product_image::get();

                foreach ($cw_product_images as $cw) {

                    Product_image::updateOrcreate(
                        [
                            'product_id' => $cw->product_image_product_id,
                            'image_id' => $cw->product_image_id,
                            'imagetype_id' => $cw->product_image_imagetype_id,
                            'filename' => $cw->product_image_filename,
                            'sortorder' => $cw->product_image_sortorder,
                            'caption' => $cw->product_image_caption,
                        ]);
                }


                echo "Importing category1 table <br>";

                DB::table('category1')->truncate();

                $cw_categories_primary = Cw_categories_primary::get();

                foreach ($cw_categories_primary as $cw) {

                    Category1::updateOrcreate(
                        [
                            'category1_id' => $cw->category_id,
                            'name' => $cw->category_name,
                            'archive' => $cw->category_archive,
                            'sort' => $cw->category_sort,
                            'description' => $cw->category_description,
                            'nav' => $cw->category_nav
                        ]);
                }

                echo "Importing category2 table <br>";

                DB::table('category2')->truncate();

                $cw_categories_secondary = Cw_categories_secondary::get();

                foreach ($cw_categories_secondary as $cw) {

                    Category2::updateOrcreate(
                        [
                            'category2_id' => $cw->secondary_id,
                            'name' => $cw->secondary_name,
                            'archive' => $cw->secondary_archive,
                            'sort' => $cw->secondary_sort,
                            'description' => $cw->secondary_description,
                            'nav' => $cw->secondary_nav
                        ]);
                }


                echo "Importing product category1 table <br>";

                DB::table('category1_product')->truncate();

                $cw_product_categories_primary = Cw_product_categories_primary::get();

                foreach ($cw_product_categories_primary as $cw) {

                    Category1_product::updateOrcreate(
                        [
                            'product_id' => $cw->product2category_product_id,
                            'category1_id' => $cw->product2category_category_id
                        ]);
                }

                echo "Importing product category2 table <br>";

                DB::table('category2_product')->truncate();

                $cw_product_categories_secondary = Cw_product_categories_secondary::get();

                foreach ($cw_product_categories_secondary as $cw) {

                    Category2_product::updateOrcreate(
                        [
                            'product_id' => $cw->product2secondary_product_id,
                            'category2_id' => $cw->product2secondary_secondary_id,
                        ]);
                }


                echo "Importing sku table <br>";

                DB::table('skus')->truncate();

                $cw_sku = Cw_Sku::get();

                foreach ($cw_sku as $cw) {
                    Sku::updateOrcreate(
                        [
                            'product_id' => $cw->sku_product_id,
                            'alt_price' => $cw->sku_alt_price,
                            'price' => $cw->sku_price,
                            'weight' => $cw->sku_weight,
                            'stock' => $cw->sku_stock,
                            'on_web' => $cw->sku_on_web,
                            'sort' => $cw->sku_sort,
                            'ship_base' => $cw->sku_ship_base,
                            'merchant_sku_id' => $cw->sku_merchant_sku_id,
                            'size' => $cw->sku_size,
                        ]);
                }

                /*import from original database*/

                echo "cleaning up product table<br>";

                $this->clean_description();

                echo "All done <br>";

            }

        public
        function xclean_description()
            {

                //    $products = Product::where('name', 'LIKE', '%quot;%')->update(['name' => str_replace("quot;",'"','name')]);
                $products = Product::where('type', 'LIKE', '%quot;%')->get();
                //   dd($products);
                foreach ($products as $p) {
                    //    [$p->name => str_replace("quot;",'"',$p->name)];
                    $newname = str_replace("&quot;", '"', $p->name);
                    $p->name = $newname;
                    //  dd($newname);
                    $p->save();
                }
                /*            $products = Product::find(873)->update(['name' => str_replace("quot;",'"','name')]);*/
            }

        public
        function products_2_shopify()
            {
                DB::table('shopify_imports')->truncate();
                $expProducts = [];
                $shopify_import = new Shopify_import;
                $productCounter = 0;

                $products = Product::where('is_on_web', TRUE)->where('category1_id', 75)->orderBy('id')->get();
                //       $products = Product::whereDate('date_modified', '>=', '2017-12-20')->orderBy('id')->get();
                // $products = Product::where('is_on_web',TRUE)->take(30)->get();

                // $products = Product::get();
                foreach ($products as $product) {
                    //    echo $product->cat1->name . '<br>';
                    //                echo $product->id . "->";
                    $productCounter++;
                    $skuCount = $product->skus()->count();
                    $imageCount = $product->images()->where(function ($query) {
                        $query->where('imagetype_id', '=', 3)->orWhere('imagetype_id', '=', 11);
                    })->count();
                    $productLine = 1;
                    $lines = $productLine + $skuCount + $imageCount + 1;
                    $skuLines = abs($skuCount - $productLine);
                    $imageLines = ($productLine + $skuLines >= $imageCount) ? 0 :
                        abs($productLine + $skuLines - $imageCount);
                    $i = 1;
                    $shopify_import->updateOrCreate($this->ProductLine($product, 0));
                    //skuLines
                    for ($i = 1; $i <= $skuLines; $i++) {
                        $shopify_import->updateOrCreate($this->SkuLines($product, $i));
                    }
                    //imageLines
                    for ($i = 1; $i <= $imageLines; $i++) {
                        $shopify_import->updateOrCreate($this->ImageLines($product, $imageLines, $i));
                    }
                }
                //         $this->export_csv();
                dd('Done with ' . $productCounter . 'products.');
                return;
            }


        public
        function export_csv()
            {
                $csvExporter = new \Laracsv\Export();
                $shopify_import = Shopify_import::get();
                $csvExporter->build($shopify_import,
                    [
                        'Handle',
                        'Title',
                        'Body',
                        'Vendor',
                        'Type',
                        'Tags',
                        'Published',
                        'Option1 Name',
                        'Option1 Value',
                        'Option2 Name',
                        'Option2 Value',
                        'Option3 Name',
                        'Option3 Value',
                        'Variant SKU',
                        'Variant Grams',
                        'Variant Inventory Tracker',
                        'Variant Inventory Quantity',
                        'Variant Inventory Policy',
                        'Variant Fulfillment Service',
                        'Variant Price',
                        'Variant Compare at Price',
                        'Variant Requires Shipping',
                        'Variant Taxable',
                        'Variant Barcode',
                        'Image Src',
                        'Image Position',
                        'Image Alt Text',
                        'Gift Card',
                        'Variant Image',
                        'Variant Weight Unit',
                        'Variant Tax Code',
                        'SEO Title',
                        'SEO Description',
                        'Collection'
                    ]
                )->download("product_import.csv");
                dd("done");
                return;
            }

        function ProductLine($product, $i)
            {
                //        dd($product);// . '<br>';
                //    echo $product->category1_id  . "<br>";
                //     echo $product->category2_id ? $product->cat2->name : 0;
                //     echo $product->category1_id ? $product->cat1->name : null  . "<br>";
                ////     echo $product->product_id . "<br>";
                //    dd($product->images->where('imagetype_id',11));
                $productLine = [
                    'product_id' => $product->id,
                    'Handle' => str_replace(' ', '_', str_replace('"', '', strtolower($product->name))) . "_" . $product->id,
                    'Title' => $product->name,
                    'Body' => $product->description,
                    'Vendor' => NULL,
                    'Type' => $product->category2_id ? $product->cat2->name : null, // $this->getCategory2($product->category2_id),
                    'Tags' => $product->keywords,
                    'Published' => $product->is_on_web,
                    'Option1 Name' => $this->getSize($product->id, $i) ? 'Size' : 'Title',
                    'Option1 Value' => $this->getSize($product->id, $i) ? $this->getSize($product->id, $i) : $product->name,
                    'Option2 Name' => NULL,                  //can be blank
                    'Option2 Value' => NULL, //$this->getCategory2($product->id, $i),                  //can be blank
                    'Option3 Name' => NULL,                   //can be blank
                    'Option3 Value' => NULL,                  //can be blank
                    'Variant SKU' => $this->getSku($product->id, $i),                   //can be blank
                    'Variant Grams' => $this->getWeight($product->id, $i),
                    'Variant Inventory Tracker' => 'shopify',    //can be blank
                    'Variant Inventory Quantity' => $this->getQuantity($product->id, $i),
                    'Variant Inventory Policy' => 'deny', // or continue
                    'Variant Fulfillment Service' => 'manual',
                    'Variant Price' => $this->getPrice($product->id, $i),
                    'Variant Compare at Price' => NULL,
                    'Variant Requires Shipping' => TRUE,
                    'Variant Taxable' => TRUE,
                    'Variant Barcode' => NULL,                //can be left blank
                    'Image Src' => $this->getImage($product->id),
                    'Image Position' => 1,
                    'Image Alt Text' => $product->name,
                    'Gift Card' => FALSE,
                    'Variant Image' => NULL,
                    'Variant Weight Unit' => 'lb',
                    'Variant Tax Code' => NULL,
                    'SEO Title' => $product->name,
                    'SEO Description' => $product->description,
                    'Collection' => $product->category1_id ? $product->cat1->name : null,
                ];
                //      dd($productLine);

                return $productLine;
            }

        function SkuLines($product, $i)
            {
                $skuLine = [
                    'product_id' => $product->id,
                    'Handle' => str_replace(' ', '_', $product->name) . "_" . $product->id,
                    'Title' => NULL,
                    'Body' => NULL,
                    'Vendor' => NULL,
                    'Type' => NULL,
                    'Tags' => NULL,
                    'Published' => $product->is_on_web,
                    'Option1 Name' => $this->getSize($product->id, $i) ? 'Size' : NULL,
                    'Option1 Value' => $this->getSize($product->id, $i), //$this->getCategory1($product->id, $i),
                    'Option2 Name' => NULL,                  //can be blank
                    'Option2 Value' => NULL, //$this->getCategory2($product->id, $i),                  //can be blank
                    'Option3 Name' => NULL,                   //can be blank
                    'Option3 Value' => NULL,                  //can be blank
                    'Variant SKU' => $this->getSku($product->id, $i),                   //can be blank
                    'Variant Grams' => $this->getWeight($product->id, $i),
                    'Variant Inventory Tracker' => 'shopify',    //can be blank
                    'Variant Inventory Quantity' => $this->getQuantity($product->id, $i),
                    'Variant Inventory Policy' => 'deny', // or continue
                    'Variant Fulfillment Service' => 'manual',
                    'Variant Price' => $this->getPrice($product->id, $i),
                    'Variant Compare at Price' => NULL,
                    'Variant Requires Shipping' => TRUE,
                    'Variant Taxable' => TRUE,
                    'Variant Barcode' => NULL,                //can be left blank
                    'Image Src' => $this->getImage2($product->id),
                    'Image Position' => $this->getImage2($product->id) ? 2 : NULL,
                    'Image Alt Text' => NULL,
                    'Gift Card' => NULL,
                    'Variant Image' => NULL,
                    'Variant Weight Unit' => 'lb',
                    'Variant Tax Code' => NULL,
                    'SEO Title' => NULL,
                    'SEO Description' => NULL,
                    'Collection' => null
                ];
                //     if ($i>0){dd($skuLine);}
                return $skuLine;
            }

        function ImageLines($product, $imageLines, $i)
            {
                $imageLine = [
                    'product_id' => $product->id,
                    'Handle' => str_replace(' ', '_', $product->name) . "_" . $product->id,
                    'Title' => NULL,
                    'Body' => NULL,
                    'Vendor' => NULL,
                    'Type' => NULL,
                    'Tags' => NULL,
                    'Published' => null,
                    'Option1 Name' => NULL,
                    'Option1 Value' => NULL,
                    'Option2 Name' => NULL,
                    'Option2 Value' => NULL,
                    'Option3 Name' => NULL,
                    'Option3 Value' => NULL,
                    'Variant SKU' => NULL,
                    'Variant Grams' => NULL,
                    'Variant Inventory Tracker' => NULL,
                    'Variant Inventory Quantity' => NULL,
                    'Variant Inventory Policy' => NULL,
                    'Variant Fulfillment Service' => NULL,
                    'Variant Price' => NULL,
                    'Variant Compare at Price' => NULL,
                    'Variant Requires Shipping' => NULL,
                    'Variant Taxable' => NULL,
                    'Variant Barcode' => NULL,                //can be left blank
                    'Image Src' => $this->getImage2($product->id),
                    'Image Position' => 3,
                    'Image Alt Text' => NULL,
                    'Gift Card' => NULL,
                    'Variant Image' => NULL,
                    'Variant Weight Unit' => NULL,
                    'Variant Tax Code' => NULL,
                    'SEO Title' => NULL,
                    'SEO Description' => NULL,
                    'Collection' => NULL
                ];
                return $imageLine;
            }


        function getImage($product_id)
            {
                $image = [''];
                $skus = Product::findOrfail($product_id)->images;
                $imageAddress = "http://www.illuminearts.com/cw4/images/orig/";
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

        function getSku($product_id, $v_count)
            {
                $sku = [];
                $skus = Product::findOrFail($product_id)->skus;
                foreach ($skus as $skuItem) {
                    $sku[] = $skuItem->merchant_sku_id;
                }
                if (!$sku) {
                    return (NULL);
                };
                return $sku[$v_count];
            }

        function getWeight($product_id, $v_count)
            {
                $weights = [];
                $skus = Product::findOrFail($product_id)->skus;
                foreach ($skus as $sku) {
                    $weights[] = $sku->weight;
                }
                if (!$weights) {
                    return (NULL);
                };
                return $weights[$v_count] / 0.035274;
            }

        function getSize($product_id, $v_count)
            {
                $sizes = [];
                $skus = Product::findOrFail($product_id)->skus;
                /*                echo $v_count;
                                dd("size=" . $skus);*/

                foreach ($skus as $sku) {
                    $sizes[] = $sku->size;
                    //                  dd($sku->size);
                }
                if (!$sizes) {
                    return FALSE;
                };
                //     dd($sizes[$v_count]);
                return $sizes[$v_count];
            }

        function getQuantity($product_id, $v_count)
            {
                $quantity = [];
                $skus = Product::findOrFail($product_id)->skus;
                foreach ($skus as $sku) {
                    $quantity[] = $sku->stock;
                }
                if (!$quantity) {
                    return (NULL);
                };
                return $quantity[$v_count];
            }

        function getPrice($product_id, $v_count)
            {
                //     dd($v_count);
                $skus = Product::findOrFail($product_id)->skus;
                $prices = [];
                foreach ($skus as $sku) {
                    $prices[] = $sku->price;
                }
                if (!$prices) {
                    return (NULL);
                };
                return $prices[$v_count];
            }

    /*        function getCategory1($product_id)
                {
                    $products = Product::findOrFail($product_id)->cat1;
                    echo $product_id;
                    foreach ($products as $product) {
                        dd($product);
                        return $product->name;
                    }
                }*/

        function getCategory1($category1_id)
            {
                $category2 = Category1::where('category1_id', '=', $category1_id);
                foreach ($category2 as $cat) {
                    return $cat->name;
                }
            }

        function getCategory2($category2_id)
            {
                //         dd($product_id);
                $category2 = Category1::where('category2_id', $category2_id);
                foreach ($category2 as $cat) {
                    return $cat->name;
                }
            }

        function makeSkuSize()
            {
                $skus = Sku::get();
                foreach ($skus as $sku) {
                    $line2 = explode("-", $sku->merchant_sku_id);
                    //      dd($line2);
                    $size = array_pop($line2);
                    if ($size == 'PR8.5x11' or $size == 'PR11x17') {
                        //      echo end($line2);
                        $sku->size = substr($size, 2);
                    } else {
                        $sku->size = '';
                    }

                    $sku->save();
                }
            }

        public
        function clean_description()
            {
                echo "cleanup 1<br>";
                $products = Product::get();
                foreach ($products as $product) {
                    //     echo "cleanup 1:" . $product->name . "<br>";

                    $prefix = '<p class="normal">';

                    $str = $product->description;

                    $clean_str0 = str_replace($prefix, "", $str);

                    $prefix = '<p class="smallPrint">';
                    $clean_str11 = str_replace($prefix, "", $clean_str0);

                    $prefix = '<div class="normal">';
                    $clean_str12 = str_replace($prefix, "", $clean_str11);

                    $prefix = '<span class="normal">';
                    $clean_str12 = str_replace($prefix, "", $clean_str11);

                    $prefix = '</span>';
                    $clean_str12 = str_replace($prefix, "", $clean_str11);


                    $prefix = '</div>';
                    $clean_str12 = str_replace($prefix, "<br>", $clean_str12);

                    $clean_str2 = str_replace("</p>", "<br>", $clean_str12);
                    $clean_str3 = str_replace("<p>", "", $clean_str2);
                    //            echo $product->id . ": " . $clean_str3 . '<br>';

                    $line2 = explode("<br>", $clean_str3);
                    $card_type = "NULL";
                    if (array_key_exists(1, $line2)) {
                        //               echo $product->id;
                        $card_type = $line2[1];
                        //       echo $card_type;
                        //       dd($line2);
                        unset($line2[1]);
                    }
                    /*                    echo "new=" . implode($line2) . "<br>";
                                        echo "card_type:" . $card_type . "<br>";*/

                    $product->description = implode($line2);
                    $product->type = $card_type;
                    $product->save();
                }

                //       $products = Product::where('type', 'LIKE', '%quot;%')->get();
                echo "cleanup 2<br>";
                $products = Product::get();
                //   dd($products);

                foreach ($products as $p) {
                    //        echo "cleanup 2:" . $p->name . "<br>";

                    //    [$p->name => str_replace("quot;",'"',$p->name)];
                    $newname = str_replace("&quot;", '"', $p->name);
                    $p->name = $newname;
                    $newname = str_replace("&quot;", '"', $p->description);
                    $p->description = $newname;
                    $newname = str_replace("&quot;", '"', $p->type);
                    $p->type = $newname;
                    //  dd($newname);
                    $p->save();
                }

                echo "cleanup 3<br>";
                $products = Product::get();
                //   dd($products);
                foreach ($products as $p) {
                    //    [$p->name => str_replace("quot;",'"',$p->name)];
                    $newname = str_replace("&nbsp;", ' ', $p->name);
                    $p->name = $newname;
                    $newname = str_replace("&nbsp;", ' ', $p->description);
                    $p->description = $newname;
                    $newname = str_replace("\r\n", '', $p->type); // remove carriage returns
                    $p->type = $newname;
                    $newname = str_replace("&nbsp;", ' ', $p->type);
                    $p->type = $newname;
                    //  dd($newname);
                    $p->save();
                }

                return false;
            }

    }
