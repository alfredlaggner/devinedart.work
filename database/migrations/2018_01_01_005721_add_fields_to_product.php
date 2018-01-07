<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class AddFieldsToProduct extends Migration
    {
    /**
     * Run the migrations.
     *
     * @return void
     */
        public function up()
            {
                Schema::connection('wholesale')->table('products', function (Blueprint $table) {
                    $table->integer('product_id')->nullable();
                    $table->string('type', 255)->nullable();
                    $table->string('merchant_product_id', 255)->nullable();
                    $table->string('preview_description', 255)->nullable();
                    $table->boolean('is_on_web')->nullable();
                    $table->boolean('is_archive')->nullable();
                    $table->boolean('is_ship_charge')->nullable();
                    $table->integer('tax_group_id')->nullable();
                    $table->string('special_description', 255)->nullable();
                    $table->string('keywords', 255)->nullable();
                    $table->string('out_of_stock_message', 255)->nullable();
                    $table->string('custom_info_label', 255)->nullable();
                });
            }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
        public function down()
            {
                Schema::connection('wholesale')->table('products', function (Blueprint $table) {

                    $table->dropColumn('product_id');
                    $table->dropColumn('type');
                    $table->dropColumn('merchant_product_id');
                    $table->dropColumn('preview_description');
                    $table->dropColumn('is_on_web');
                    $table->dropColumn('is_archive');
                    $table->dropColumn('is_ship_charge');
                    $table->dropColumn('tax_group_id');
                    $table->dropColumn('special_description');
                    $table->dropColumn('keywords');
                    $table->dropColumn('out_of_stock_message');
                });
            }
    }
