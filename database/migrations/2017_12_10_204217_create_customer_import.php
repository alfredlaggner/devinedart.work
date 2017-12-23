<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateCustomerImport extends Migration
    {
    /**
     * Run the migrations.
     *
     * @return void
     */
        public function up()
            {
                Schema::create('customer_import', function (Blueprint $table) {
                    $table->increments('id');
                    $table->string('First Name')->nullable();
                    $table->string('Last Name')->nullable();
                    $table->string('Email')->nullable();
                    $table->string('Company')->nullable();
                    $table->string('Address1')->nullable();
                    $table->string('Address2')->nullable();
                    $table->string('City')->nullable();
                    $table->string('Province Code')->nullable();
                    $table->string('Province')->nullable();
                    $table->string('Code')->nullable();
                    $table->string('Country')->nullable();
                    $table->string('Country Code')->nullable();
                    $table->string('Zip')->nullable();
                    $table->string('Phone')->nullable();
                    $table->boolean('Accepts Marketing')->nullable();
                    $table->string('Tags')->nullable();
                    $table->text('Note')->nullable();
                    $table->boolean('Tax Exempt')->nullable();
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
                Schema::dropIfExists('customer_import');
            }
    }
