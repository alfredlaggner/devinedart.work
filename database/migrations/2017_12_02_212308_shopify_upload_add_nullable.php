<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class ShopifyUploadAddNullable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('shopify_imports', function (Blueprint $table) {
            /*           $table->string('Handle')->nullable()->change();
                    $table->string('Title')->nullable()->change();
                       $table->text('Body')->nullable()->change();
                       $table->string('Vendor')->nullable()->change();
                       $table->string('Type')->nullable()->change();
                       $table->text('Tags')->nullable()->change();
                       $table->boolean('Published')->nullable()->change();
                       $table->string('Option1 Name')->nullable()->change();
                       $table->string('Option1 Value')->nullable()->change();
                       $table->string('Option2 Name')->nullable()->change();
                       $table->string('Option2 Value')->nullable()->change();
                       $table->string('Option3 Name')->nullable()->change();
                       $table->string('Option3 Value')->nullable()->change();
                       $table->string('Variant SKU')->nullable()->change();
                       $table->integer('Variant Grams')->nullable()->change();
                       $table->string('Variant Inventory Tracker')->nullable()->change();
                       $table->integer('Variant Inventory Quantity')->nullable()->change();
                       $table->string('Variant Inventory Policy')->nullable()->change();
                       $table->string('Variant Fulfillment Service')->nullable()->change();
                       $table->decimal('Variant Price', 8, 2)->nullable()->change();
                       $table->decimal('Variant Compare at Price', 8, 2)->nullable()->change();
                       $table->boolean('Variant Requires Shipping')->nullable()->change();
                       $table->boolean('Variant Taxable')->nullable()->change();
                       $table->string('Variant Barcode')->nullable()->change();
                       $table->string('Image Src')->nullable()->change();
                       $table->integer('Image Position')->nullable()->change();
                       $table->text('Image Alt Text')->nullable()->change();
                       $table->boolean('Gift Card')->nullable()->change();
                       $table->string('Variant Image')->nullable()->change();
                       $table->string('Variant Weight Unit')->nullable()->change();
                       $table->string('Variant Tax Code')->nullable()->change();
                       $table->string('SEO Title')->nullable()->change();
                       $table->string('SEO Description')->nullable()->change();*/
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        //
    }
}
