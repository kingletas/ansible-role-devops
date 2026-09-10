<?php

/* Find bootstrap path */
$rootPath = '/app';
/* Include Magento bootstrap file */
require_once $rootPath . '/app/bootstrap.php';

/* Create git hook class autoloader */
$gitHooks = [];
/**
 * @param $class
 * @return mixed
 */
function phpstanMagento($class)
{
    global $gitHooks;
    if (isset($gitHooks[$class])) {
        return $gitHooks[$class];
    }

    try {
        /* Get Magento ObjectManager */
        $bootstrap     = \Magento\Framework\App\Bootstrap::create(BP, $_SERVER);
        $objectManager = $bootstrap->getObjectManager();

        $objectManager->get($class);
        $gitHooks[$class] = true;
    } catch (\Exception $e) {
        $gitHooks[$class] = false;
    }

    return $gitHooks[$class];
}
spl_autoload_register('phpstanMagento');
