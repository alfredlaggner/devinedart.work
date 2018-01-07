<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class ProductsChangeType extends Migration
    {
    /**
     * Run the migrations.
     *
     * @return void
     */
        public function up()
            {
                Schema::connection('wholesale')->table('products', function (Blueprint $table) {
                    $table->text('type')->change();
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

                    $table->string('type', 255)->change;
                });
            }
    }
