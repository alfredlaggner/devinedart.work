<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateProductImport extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('shopify_imports', function (Blueprint $table) {
            $table->increments('id');
            $table->string('Handle');
            $table->string('Title');
            $table->text('Body');
            $table->string('Vendor');
            $table->string('Type');
            $table->text('Tags');
            $table->boolean('Published');
            $table->string('Option1 Name');
            $table->string('Option1 Value');
            $table->string('Option2 Name');
            $table->string('Option2 Value');
            $table->string('Option3 Name');
            $table->string('Option3 Value');
            $table->string('Variant SKU');
            $table->integer('Variant Grams');
            $table->string('Variant Inventory Tracker');
            $table->integer('Variant Inventory Quantity');
            $table->string('Variant Inventory Policy');
            $table->string('Variant Fulfillment Service');
            $table->float('Variant Price',8,2);
            $table->float('Variant Compare at Price',8,2);
            $table->boolean('Variant Requires Shipping');
            $table->boolean('Variant Taxable');
            $table->string('Variant Barcode');
            $table->string('Image Src');
            $table->integer('Image Position');
            $table->text('Image Alt Text');
            $table->boolean('Gift Card');
            $table->string('Variant Image');
            $table->string('Variant Weight Unit');
            $table->string('Variant Tax Code');
            $table->string('SEO Title');
            $table->string('SEO Description');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('shopyfy_import');
    }
}
