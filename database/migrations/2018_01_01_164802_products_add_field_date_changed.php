<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class ProductsAddFieldDateChanged extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::connection('wholesale')->table('products', function (Blueprint $table) {
            $table->date('date_modified')->nullable();
            $table->text('preview_description')->change();
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

            $table->dropColumn('date_modified');
            $table->string('preview_description',255)->change;
        });
    }
}
