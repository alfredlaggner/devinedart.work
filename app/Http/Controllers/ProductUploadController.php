<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use App\Category2;
use App\Category1_product;
use App\Category2_product;
use App\Cw_product;
use App\Product;
use App\Sku;
use App\Shopify_import;
use Maatwebsite\ Excel\ Facades\ Excel;

ini_set('max_execution_time', 180 * 2); //6 minutes

class ProductUploadController extends Controller
    {


        public function original_2_import()
            {

                /*import from original database*/


                DB::table('products as p')
                    ->join('cw_products as cw', 'p.id', '=', 'cw.product_id')
                    ->update([
                        'p.description' => DB::raw('cw.product_description'),
                        'p.name' => DB::raw('cw.product_name'),
                        'p.preview_description' => DB::raw('cw.product_preview_description'),
                    ]);

              $this->clean_description();
            }


        public function xclean_description()
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

        public function products_2_shopify()
            {
                DB::table('shopify_imports')->truncate();
                $expProducts = [];
                $shopify_import = new Shopify_import;
                $productCounter = 0;

                $products = Product::whereIn('id', [315, 370, 300])->orderBy('product_id')->get();
                // $products = Product::where('is_on_web',TRUE)->take(30)->get();

                // $products = Product::get();
                foreach ($products as $product) {
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
                $this->export_csv();
                dd('Done with ' . $productCounter);
                return;
            }


        public function export_csv()
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
                $productLine = [
                    'product_id' => $product->id,
                    'Handle' => str_replace(' ', '_', $product->name) . "_" . $product->id,
                    'Title' => $product->name,
                    'Body' => $product->description,
                    'Vendor' => NULL,
                    'Type' => $this->getCategory2($product->id),
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
                    'Collection' => $this->getCategory1($product->id)
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
                $skus = Product::findOrFail($product_id)->images;
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

        function getCategory1($product_id)
            {
                $products = Product::findOrFail($product_id)->cat1;
                foreach ($products as $product) {
                    return $product->name;
                }
            }

        function getCategory2($product_id)
            {
                $products = Product::findOrFail($product_id)->cat2;
                foreach ($products as $product) {
                    return $product->name;
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

            public function clean_description()
    {
        $products = Product::all();
        foreach ($products as $product) {

            $prefix = '<p class="normal">';
            $str = $product->description;
            $clean_str0 = str_replace($prefix, "", $str);

            $prefix = '<p class="smallPrint">';
            $clean_str11 = str_replace($prefix, "", $clean_str0);

            $prefix = '<div class="normal">';
            $clean_str12 = str_replace($prefix, "", $clean_str11);

            $prefix = '</div>';
            $clean_str12 = str_replace($prefix, "<br>", $clean_str12);

            $clean_str2 = str_replace("</p>", "<br>", $clean_str12);
            $clean_str3 = str_replace("<p>", "", $clean_str2);
            //            echo $product->id . ": " . $clean_str3 . '<br>';

            $line2 = explode("<br>", $clean_str3);
            $card_type="none";
            if (array_key_exists(1,$line2)) {
                //               echo $product->id;
                $card_type = $line2[1];
         //       echo $card_type;
         //       dd($line2);
                unset($line2[1]);
            }
            echo "<br>original= " . $product->description;
            echo "new=".implode($line2)."<br>";
            echo "card_type:" . $card_type ."<br>";

            $product->description = implode($line2);
            $product->type = $card_type;
            $product->save();

     //       $products = Product::where('type', 'LIKE', '%quot;%')->get();
            $products = Product::get();
            //   dd($products);
            foreach ($products as $p) {
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

            $products = Product::get();
            //   dd($products);
            foreach ($products as $p) {
                //    [$p->name => str_replace("quot;",'"',$p->name)];
                $newname = str_replace("&nbsp;", ' ', $p->name);
                $p->name = $newname;
                $newname = str_replace("&nbsp;", ' ', $p->description);
                $p->description = $newname;
                $newname = str_replace("&nbsp;", ' ', $p->type);
                $p->type = $newname;
                //  dd($newname);
                $p->save();
            }

        }
    }

    }
